show me example on how this is called, including full URL, header, body, credential if any: batch_update_quantity_v3 under /wms/api/v1/stock_keeping_units/ (path assumed from the item name; I did not read the OMS v3 handler)

I'll look up the actual handler in the WMS code first.

  Ran 2 shell commands

Now I'll read the OMS handler and the WMS caller.

  Ran 1 shell command

The handler is clear. Next I need the signing logic on both sides, which is the credential part.

  Ran 2 shell commands

Last, the exact way WMS builds the request (PurchaseOrder.php).

  Ran 1 shell command

I read the OMS v3 handler (oms/.../app/services/wms/api/v1/stock_keeping_units.rb:354) and the WMS caller (wms/.../app/PurchaseOrder.php:140). The path is now confirmed, so the "assumed" note in docs/integration-points.md row 9 can go.

Request

┌────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│    Item    │                                                      Value                                                       │
├────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Method     │ POST                                                                                                             │
├────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ URL        │ https://ebest.beansmile-dev.com/wms/api/v1/stock_keeping_units/batch_update_quantity_v3                          │
├────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Query      │ timestamp, sign, skip_authenticate=false. WMS also sends page=1&per_page=50&offset=0, which the handler ignores. │
├────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Header     │ Content-Type: application/json                                                                                   │
├────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Credential │ No token or Authorization header. The sign query parameter is the only credential.                               │
└────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

The URL comes from OMS_PRODUCT_V3_URL in the WMS .env, read as config('app.oms_product_v3_url'). The host shown is the .env.example value, so check the real .env for the production host.

Signature

- sign = MD5(<key> + <timestamp>), as lowercase hex.
- timestamp is Unix seconds. OMS rejects it with 401 if it is more than 5 minutes old.
- On the WMS side the key is OMS_SIGN in .env. The example value is Donki1234, and the real value may differ.
- On the OMS side the key is credentials[env].wms.key in the Rails credentials. It must match OMS_SIGN.
- A bad signature returns 401 合作者签名验证不通过！. A stale timestamp returns 401 时间戳已过期.
- In production OMS always verifies the signature. skip_authenticate=true only works in non-production environments.

Body

{
  "stock_keeping_units": [
    {
      "po_id": 1001,
      "po_number": "PO2026111501",
      "product_id": 123,
      "sku": "SKU-ABC-001",
      "store_id": 1,
      "quantity": 10,
      "barcode": "9300000000011,9300000000028",
      "supplier_name": "Sample Supplier Pty Ltd",
      "supplier_cost_in_cent": 850,
      "inc_gst": true,
      "gst": "0.85"
    }
  ]
}

- Required fields: po_id, product_id, sku, quantity, store_id, barcode, supplier_name and supplier_cost_in_cent.
- Optional fields: po_number, short_title, gst_percent, marketing_mode (self_support, consign_for_sale or platform), inc_gst and gst.
- quantity: this is an increment, not an absolute value. A negative number decrements the stock. OMS rejects the line if the stock would go below 0.
- supplier_cost_in_cent: WMS sends the price multiplied by 100, so 8.50 becomes 850.
- barcode: WMS replaces / with , before sending.
- inc_gst and gst: integration-points.md shows inc_gst as 9.35, but OMS declares it a Boolean and gst a String. WMS passes the PO values through unchanged. Treat the doc sample as wrong and use a Boolean for inc_gst and a String for gst.

curl

KEY='Donki1234'                       # OMS_SIGN in the WMS .env (example value)
TS=$(date +%s)
SIGN=$(printf '%s%s' "$KEY" "$TS" | md5 -q)   # on Linux: md5sum | cut -d' ' -f1

curl -s -X POST \
  "https://ebest.beansmile-dev.com/wms/api/v1/stock_keeping_units/batch_update_quantity_v3?timestamp=$TS&sign=$SIGN&skip_authenticate=false" \
  -H 'Content-Type: application/json' \
  -d '{"stock_keeping_units":[{"po_id":1001,"po_number":"PO2026111501","product_id":123,"sku":"SKU-ABC-001","store_id":1,"quantity":10,"barcode":"9300000000011","supplier_name":"Sample Supplier Pty Ltd","supplier_cost_in_cent":850,"inc_gst":true,"gst":"0.85"}]}'

Response

Success is HTTP 201, which WMS checks for. The body has one entry per line, and po_id links each result back to the PO line:

{
  "results": [
    { "po_id": 1001, "result": "success", "message": "success" },
    { "po_id": 1002, "result": "failure", "message": "找不到该sku" }
  ]
}

- Success: WMS sets syncback=1 on that PO line.
- Failure: WMS writes the message to syncback_message, and the line is retried on the next 15-minute run.

Behaviour to know for the vendor onboarding design

- Lookup order: OMS finds the SKU by product_id and store_id, then falls back to sku (the SKU number) and store_id.
- Per-line processing: each line runs in its own transaction. A failure on one line does not roll back the others, so always check each entry in results.
- Active promotion: if a limited-time promotion is active on the SKU, the quantity goes to the promotion's reserved stock instead.
- Supplier record: the supplier cost is saved on the SKU's supplier record. This is skipped if supplier_name equals MagicBean::Supplier::IGNORED_SUPPLIER_NAME, a constant I did not look up.
- Credential in the repo: .env.example also contains a Sentry DSN with a key. That is a credential committed to the repo, so you may want to rotate it.

I haven't run the curl against the live host.

✻ Crunched for 33s · done 12:55 am

❯ does it update the inventory available quantity?

Let me check how OMS derives "available quantity" from sku.quantity.

  Ran 1 shell command

Yes. It changes the stock quantity on the OMS SKU (sku.quantity), but it doesn't set an absolute value. It adds the sent quantity to the current one. I found no field called available_quantity in the OMS code, so I can't say how the app computes what shoppers see.

How the quantity is updated
- No active promotion: sku.quantity = old + quantity, then sku.save. A negative quantity decrements. If the result would be below 0, the line fails with 调拨库存不足，差N个.
- One active limited-time promotion:
  - A positive quantity normally goes to sku.quantity.
  - If the promotion has save_qty_to_promotion_price? off, it goes to the promotion price's reserved_quantity instead.
  - A negative quantity is taken from the promotion's reserved stock first, then from sku.quantity.
- More than one active promotion: the line fails with 有多个激活的限时优惠，请处理后再更新库存.
- Audit record: each change writes a MagicBean::OperationRecord with channel wms, for example 库存由 5 改为 15.

Other effects
- quantity is 0: WMS sends 0 for lines whose allow_sync is not Y or OMS. Stock stays the same, but the supplier cost and barcode (only if blank on OMS) are still updated.
- Other fields: gst_percent and marketing_mode are updated on the SKU when sent. short_title is updated on the item and product.

What I haven't checked: whether the app shows sku.quantity directly or subtracts reserved or in-cart quantities first. That lives in the SKU model or the customer API, and I only read the WMS handler. Do you want me to trace it? It matters for the vendor onboarding design, because the "sync stock" flag would feed this same increment path.