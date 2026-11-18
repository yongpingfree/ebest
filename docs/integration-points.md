# OMS / WMS / AWS Integration Points

Source: code in `oms/www/lvtuantuan/releases/20261112143032` and `wms/var/www/html/wms.donkibuy.com/releases/180`.
Method: static reading only. No endpoint was called, so the curl samples are untested.
"Amazon" is read as AWS (S3, CDN, Lambda thumbnails). No Amazon marketplace or MWS/SP-API code exists in either codebase.

All hosts, keys and passwords below are placeholders. The WMS code contains hard-coded credentials in comments and OMS has AWS key IDs in a comment (`aws_oss.rb`). Rotate them and remove them from source.

## 1. Overview

```
                 (1) signed REST, WMS pulls/pushes           (4) HTTPS, Jerry API
  OMS (Rails) <-------------------------------------> WMS (Laravel) <-----------> Jerry (external warehouse, probably Runbow)
     |                                                    |
     | (2) S3 presign + CDN + Lambda thumbnails           | (3) Optimo Route / Onfleet (delivery ETA)
     v
  AWS S3 / CDN / Lambda
```

WMS drives the OMS-WMS sync with the Laravel scheduler. OMS only exposes endpoints and never calls WMS.

## 2. OMS <-> WMS

Auth for all calls in this section: query parameters `timestamp` and `sign`, where `sign = MD5(shared_key + timestamp)`, plus `skip_authenticate=false`. The OMS side is `Wms::Helpers::AuthenticationHelper`; the timestamp is valid for 5 minutes.

Config on the WMS side: `config/app.php` reads these `.env` items: `OMS_SIGN` (shared key) and the URL items below.
Config on the OMS side: the shared key is checked in `Wms::Helpers::AuthenticationHelper` (I did not trace where its value is stored).

| # | Direction | Endpoint (OMS) | WMS `.env` item | WMS code | Schedule | Purpose |
|---|---|---|---|---|---|---|
| 1 | WMS pulls | `GET /wms/api/v1/orders?status=confirmed&store_id=&page=&per_page=200` | `OMS_ORDER_URL` | `Order::fetchOMSOrders`, `syncDataOfWebsite` | per store at its cutoff time, daily | Fetch confirmed orders; WMS creates its own order, skips ones that exist, and skips group-buy SKUs |
| 2 | WMS pushes | `POST /wms/api/v1/orders/batch` (`status=synced`) | `OMS_ORDER_BATCH_URL` | `Order::syncBack` | every 5 min | Acknowledge an order; OMS moves the warehouse order and its child sales orders to `synced` |
| 3 | WMS pushes | `POST /wms/api/v1/orders/batch` (`status=dispatched`, `tracking_no`, `delivery_path`, `eta`, `stockout_items`) | `OMS_ORDER_BATCH_URL` | `syncDispatchDeliveryJerry`, `syncDispatchDeliveryJerryOutofStock` | every 15 min | Report dispatch and shortages; OMS runs `deliver_and_generate_logistic` |
| 4 | WMS pushes | `POST /wms/api/v1/orders/batch` (`status=stockout`) | `OMS_ORDER_BATCH_URL` | `syncDispatchDeliveryJerryOutofStock` (`Order.php:290`) | every 15 min | Mark an order out of stock when Jerry scanned it as outofstock |
| 5 | WMS pushes | `POST /wms/api/v1/orders/batch_update_delivery_time` | `OMS_ORDER_TIME_URL` | `Order::syncDeliveryTime` | every 15 min | Delivery date, ETA and tracking link for merchant delivery |
| 6 | WMS pulls | `GET /wms/api/v1/stock_keeping_units?store_id=&per_page=2000&order_by=updated_at desc` | `OMS_PRODUCT_URL` | `Product::syncData`, `syncOMSProducts` | hourly (daily 20:00 in the non-production branch) | Product master: name, SKU, barcode, dimensions, image, on_sale |
| 7 | WMS pushes | `POST /wms/api/v1/stock_keeping_units/batch_update_quantity` | `OMS_PRODUCT_V1_URL` | `Transfer.php:57` | on transfer | v1 stock increment or decrease for transfers, no supplier data |
| 8 | WMS pushes | `POST /wms/api/v1/stock_keeping_units/batch_update_quantity_v2` | `OMS_PRODUCT_V2_URL` | no caller found in this release | not found | v2: adds `po_id`, supplier, cost, barcode, GST, marketing mode |
| 9 | WMS pushes | `batch_update_quantity_v3` under `/wms/api/v1/stock_keeping_units/` (path assumed from the item name; I did not read the OMS v3 handler) | `OMS_PRODUCT_V3_URL` | `PurchaseOrder::syncPOtoOMS`; also `V1/PurchaseOrderController.php:332` | every 15 min, or on manual action | Stock increment and supplier cost from an approved PO. Lines with `allow_sync` not Y/OMS are sent with quantity 0 |
| 10 | not found | `GET /wms/api/v1/stores` | none | no caller found | not found | Store list; unused by WMS in this release |
| 10a | WMS pushes | `PUT` to `OMS_STOCK_KEEPING_UNIT_UPDATE_URL` | `OMS_STOCK_KEEPING_UNIT_UPDATE_URL` | `ProductController.php:128`, `V1/ProductController.php:54` | on manual edit | Update a product's short title in OMS |

Notes:
- Row 9: for each PO line the payload has `sku`, `product_id`, `quantity`, `store_id`, `supplier_name`, `supplier_cost_in_cent`, `barcode`, `po_id`, `po_number`, `inc_gst`, `gst`. Only POs where every line sharing the PO number is `approved` are sent.
- OMS applies the quantity as an increment. When promotion stock exists, a decrease takes from the reserved quantity first and fails if the total is short.

Sample (order pull):

```bash
TS=$(date +%s)
SIGN=$(printf '%s%s' "$OMS_SIGN" "$TS" | md5)      # macOS; use md5sum | cut -d' ' -f1 on Linux
curl -s "https://<oms-host>/wms/api/v1/orders?status=confirmed&store_id=1&page=1&per_page=200&timestamp=$TS&sign=$SIGN&skip_authenticate=false"
```

Sample (acknowledge an order):

```bash
curl -s -X POST "https://<oms-host>/wms/api/v1/orders/batch?timestamp=$TS&sign=$SIGN&skip_authenticate=false" \
  -H 'Content-Type: application/json' \
  -d '{"orders":[{"no":"<order-no>","status":"synced","courier":"express","synced_at":"2026-11-16 10:00:00","tracking_no":""}]}'
```

Sample (PO stock increment):

```bash
curl -s -X POST "https://<oms-host>/wms/api/v1/stock_keeping_units/batch_update_quantity_v3?timestamp=$TS&sign=$SIGN&skip_authenticate=false" \
  -H 'Content-Type: application/json' \
  -d '{"stock_keeping_units":[{"sku":"<sku>","product_id":123,"quantity":10,"store_id":1,"supplier_name":"<name>","supplier_cost_in_cent":850,"barcode":"<barcode>","po_id":1,"po_number":"2026111501","inc_gst":9.35,"gst":0.85}]}'
```

## 3. WMS <-> Jerry (external warehouse)

Config (WMS `.env` via `config/app.php`): `JERRY_CREATEASN_URL`, `JERRY_SHIPMENT_URL`, `JERRY_STORAGEINFO_URL`, `JERRY_STOCK_URL`, `JERRY_USERNAME`, `JERRY_API_KEY`, `JERRY_PASSWORD`, `JERRY_TOKEN_KEY`, `JERRY_USE_PRODUCT_ID_AS_SKU`. Per-store credentials are stored in the `websites` table (`jerry_username`, `jerry_api_key`, `jerry_password`).

| # | Direction | Endpoint item | Code | Schedule | Purpose |
|---|---|---|---|---|---|
| 11 | WMS pushes | `JERRY_CREATEASN_URL` | `PurchaseOrder::pushASN` | every 15 min (`syncwithJerry`) | Inbound notice for an audited PO. Lines with `allow_sync` Y or Jerry. Fields: supplier, SKU, barcode, name, due date, quantity |
| 12 | WMS pushes | `JERRY_CREATEASN_URL` / `JERRY_STORAGEINFO_URL` | `Product::pushUpdateASN`, `syncJerryProducts` | hourly | Product info for up to 2000 products per store, in batches of 100 |
| 13 | WMS pushes | `JERRY_SHIPMENT_URL` | `Order::pushOrdertoJerry`, `pushOrderToJerryeMetroByID` | every 15 min | Outbound shipment (`msgType=pushUnCreatedShipments`, digest = base64(MD5(user + 1 + msgType + password))). The response carries article ID, consignment ID and label PDF URL |
| 14 | WMS pushes | `JERRY_SHIPMENT_URL` | `Transfer` sync (`SyncTransfersData`) | every 15 min | Transfer shipments |
| 15 | WMS pulls | `JERRY_STOCK_URL` | `Website::getStockfromJerry`, `Order::getOutofStockSKU` | every 15 min | Stock by UPC, used to find short quantity on an order |
| 16 | Jerry pushes | `POST /api/order/updateOrderStatusByJerry` (WMS) | `OrderController@updateOrderStatusByJerry` | on event | Callback with the scan result (`jerry_scan` all or outofstock) that drives rows 3 and 4 |

Sample (stock query):

```bash
curl -s -X POST "$JERRY_STOCK_URL" -H 'Content-Type: application/json' \
  -d '{"USERNAME":"<jerry-user>","APIPASSWORD":"<jerry-key>","UPCItems":["<barcode>"]}'
```

## 4. WMS <-> delivery services

| # | Endpoint | Config | Code | Purpose |
|---|---|---|---|---|
| 17 | Optimo Route `get_scheduling_info`, `get_completion_details`, `get_routes` | `OPTIMO_ROUTE_URL`, `OPTIMO_ROUTE_KEY` | `Order` ETA/ATA sync, `SyncATAs` daily 00:05 Sydney | Scheduled ETA and actual arrival for merchant delivery |
| 18 | Onfleet `tasks/shortId/{id}`, `tasks/all` | `ONFLEET_URL`, `ONFLEET_KEY` | `Order` ETA sync | ETA for orders whose tracking is an Onfleet short ID |

Sample: `curl -s -u "<ONFLEET_KEY>:" https://onfleet.com/api/v2/tasks/shortId/<id>`

## 5. OMS <-> AWS

Config: OMS Rails credentials `credentials.<env>.aws` with `app_key`, `app_secret`, `bucket`, `cdn_host`, `thumbnail_prefix_path`, loaded by `config/initializers/aws_init.rb`. Edited with `rails credentials:edit` and the matching master key.

| # | Integration | Where | Purpose |
|---|---|---|---|
| 19 | S3 presigned PUT | `GET /mgt/api/v1/aws_oss/meta?key=<name>&content_type=<type>` (admin session required) | Returns `presigned_url` (10 min) and `public_url`. Object key is `images/<uuid>-<name>`, `public-read` |
| 20 | CDN | `AWS_CDN_HOST` (production `cdn.minimall.donkibuy.com`) | Public image URL stored on the product |
| 21 | Lambda thumbnails | `GenerateAwsLambdaImageJob` (production only) | Requests `<cdn>/<750xAUTO>/<path>` for each image. After all succeed, OMS saves the thumbnail URLs and deletes the originals through `Aws::CustomOss.delete_file` |
| 22 | SNS | gem `aws-sdk-sns` is in the Gemfile | I found no call to it in `app` or `lib` |

Sample (upload):

```bash
curl -s -b cookies.txt "https://<oms-host>/mgt/api/v1/aws_oss/meta?key=a.png&content_type=image/png"
curl -s -X PUT "<presigned_url>" -H 'x-amz-acl: public-read' -H 'Content-Type: image/png' --data-binary @a.png
```

## 6. Other external services in OMS (outside OMS/WMS/AWS)

Listed because a vendor system will not need them: Aliyun OSS, Aliyun push and Elasticsearch, Qiniu, Luosimao SMS, SendGrid, SMTP, Klaviyo, Stripe, WeChat pay and authorize, Google Translate, AliExpress, Sentry. Credentials are in `credentials.<env>` and initializers under `config/initializers/`.

## 7. Integration points for vendor onboarding

New or changed items, in line with spec chapter 6 (DEP numbers):

| Ref | System | Change | Type |
|---|---|---|---|
| DEP-1 | OMS | Service account for the vendor system with limited rights on `items` (create, `import`, `async_import`) and store, category, brand lookups. Today only an admin-session login exists | Update |
| DEP-2 | OMS / WMS | Read-only stock and sales query by vendor and SKU. Today the SKU API returns all current products and sales only exist as admin reports | New |
| DEP-3 | OMS | Endpoint that sets stock to an absolute value, or an adjustment type for corrections, for vendor-warehouse stock. Today only increments exist | New |
| DEP-3 | WMS / OMS | Rule so that vendor-held stock is not also added by the PO sync in row 9 | Update |
| DEP-4 | WMS | REST endpoint to create a PO (today creation uses UI routes `createPOTMP`, `convertPO`, and the bulk file `formSubmitPOFile`) | New |
| DEP-4 | WMS | PO approval and received-quantity notification to the vendor system, or a polling endpoint; today only `POConfirm`/`POReject` UI routes exist | New |
| DEP-6 | WMS | Service-account access to `suppliers` (create, update, query by business number) and duplicate check | Update |
| DEP-8 | OMS / WMS | Per-vendor order lines for dispatch and next-day delivery lists, plus shortage and return feedback | New |
| DEP-5 | WMS | No change: vendor stock reaches Jerry only through the existing audited-PO inbound notice (row 11) | None |
| DEP-7 | OMS or new | Image upload through `aws_oss/meta`, or a separate least-privilege AWS account (spec Q16) | Update |
| Auth | OMS / WMS | A single service-account method with rotatable keys and stronger signing replacing MD5 + shared key | Update |
| DEP-9 | new | Outbound email for vendor notices; OMS mail is for customers | New |
