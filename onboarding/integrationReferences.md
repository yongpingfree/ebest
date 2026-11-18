check the code in oms and wms, current how they sync data on order, PO, inventory?

  Ran 2 shell commands

Commands are thin; they delegate to model methods. Let me read the bodies.

  Ran 6 shell commands

Reading the PO and inventory sync code now.

  Searched for 1 pattern, ran 4 shell commands

Here is how OMS and WMS sync, from reading the code. I didn't run anything, so none of it is tested.

How they talk to each other
- WMS pulls and pushes on a Laravel scheduler (Console/Kernel.php). OMS never calls WMS.
- WMS calls the OMS endpoints under /wms/api/v1/. Every call is signed with MD5(shared key + timestamp), which is the weak MD5 signing flagged in spec section 6.2.
- WMS also talks to the external warehouse system (named "Jerry" in the code), which is probably Runbow.

Orders (OMS → WMS → OMS)

┌─────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│    Step     │                                                         Mechanism                                                          │
├─────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│             │ Per store, at its own cutoff time, Order::syncDataOfWebsite calls GET orders with status=confirmed, 200 per page. It       │
│ Pull        │ creates a WMS order from each one, skips orders that already exist, and skips group-buy SKUs. WMS adds the pickup number   │
│             │ and delivery path.                                                                                                         │
├─────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Acknowledge │ Every 5 minutes, syncBack posts status=synced to POST orders/batch. OMS then marks the order and its child sales orders as │
│             │  synced.                                                                                                                   │
├─────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Fulfil      │ Every 15 minutes, pushOrdertoJerry sends orders to Jerry. getOutofStockSKU reads Jerry stock and records the short         │
│             │ quantity (need_qty).                                                                                                       │
├─────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Dispatch    │ Every 15 minutes, orders Jerry has fully scanned are posted back as dispatched, with tracking number, delivery path and    │
│             │ ETA. OMS then runs deliver_and_generate_logistic. Short-stocked orders are posted with the shortage list.                  │
├─────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Delivery    │ For merchant delivery, syncDeliveryTime posts the ETA and tracking link to batch_update_delivery_time.                     │
│ time        │                                                                                                                            │
└─────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

## POs and inventory (WMS → OMS)
- Every 15 minutes, syncPOtoOMS picks up PO lines that meet all of these:
  - the PO is approved;
  - every line sharing that PO number is approved (icount = 1);
  - the line hasn't been synced yet;
  - the line is allowed to sync, via allow_sync Y or OMS, or an approve date after a config cutoff.
- For each line it sends quantity, supplier name, cost in cents, barcode, GST and PO number to the OMS "v3 batch update" endpoint.
- OMS adds the quantity as an increment, not an overwrite. When promotion stock exists, it applies the increase to the reserved quantity first. It also saves or updates the supplier cost.
- Lines where allow_sync is not Y or OMS are still sent, with quantity 0 so the cost is still recorded.
- Failures are written back to syncback_message, and successful lines are marked syncback=1.

## POs and inventory (WMS ↔ Jerry)
- updatePOStatus marks audited POs as readytojerry.
- syncwithJerry then calls pushASN, which creates an inbound notice in Jerry.

## Products (OMS → WMS)
- Hourly in production, or daily at 20:00 in the other branch, Product::syncData pulls up to 2000 products per store, newest first, from OMS.
- WMS then pushes product updates to Jerry (pushUpdateASN, in batches of 100) and refreshes PO product data.

Transfers. SyncTransfersData runs every 15 minutes. It sends transfers flagged syncback to Jerry, as far as I can tell from the command.

## What this means for the spec
- Stock only enters OMS through an approved WMS PO. The vendor system's inventory should follow the same route, which matches the 6.1 DEP-3 wording.
- OMS has no "set quantity to N" endpoint. It only adds increments, so a vendor stock correction needs a new endpoint or a negative adjustment.
- OMS orders are not split by vendor, so there is no per-vendor order feed. That gap is DEP-8.
- WMS creates POs through its UI, not an API. That is the DEP-4 gap.

I didn't look at how OMS reserves or deducts stock when a customer places an order, so I can't confirm the full inventory picture. Should I read that part before I add this to the spec?