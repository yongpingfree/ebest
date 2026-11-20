#!/usr/bin/env python3
"""Fetch every item from minimall /app/api/v1/items (paged via x-total-pages header).
Usage: python3 fetch_all_items.py [out.json] [--stores 2,3,4]

The endpoint only returns what the caller's channel and store can see. Without headers it answers
as channel "mini_program" of the default store (2, Sydney), which hides items sold only in the app
(e.g. the 冈本 range). So every sweep is repeated for each channel (app, mini_program, web) and the
results are merged by item id. Other stores (3, 4) have their own catalogues and are opt-in.

The list is ordered by updated_at, so items edited while we page shift between pages and would be
skipped. To avoid that we use a large page size, de-duplicate by id, and repeat the sweep (merging
by id) until the number of distinct items reaches the x-total reported by the API or stops growing."""
import json, sys, time, urllib.request

BASE = "https://minimall.donkibuy.com/app/api/v1/items"
PER_PAGE, MAX_SWEEPS = 100, 5
CHANNELS = ["app", "mini_program", "web"]
args = sys.argv[1:]
stores = ["2"]
if "--stores" in args:
    i = args.index("--stores"); stores = args[i + 1].split(","); del args[i:i + 2]
out = args[0] if args else "items.json"


def get(page, headers):
    for attempt in range(4):
        try:
            req = urllib.request.Request(f"{BASE}?page={page}&per_page={PER_PAGE}", headers=headers)
            with urllib.request.urlopen(req, timeout=60) as r:
                total, pages = int(r.headers.get("x-total", 0)), int(r.headers.get("x-total-pages", 1))
                data = json.load(r)
            return total, pages, data if isinstance(data, list) else data.get("items", data.get("data", []))
        except Exception:
            if attempt == 3: raise
            time.sleep(2 ** attempt)


def sweep_all(headers, label, items):
    """Page through one channel/store view until every distinct item is seen (or no progress)."""
    total = 0
    for sweep in range(1, MAX_SWEEPS + 1):
        page, pages, seen = 1, 1, set()
        while page <= pages:
            total, pages, data = get(page, headers)
            for it in data:
                items[it["id"]] = it      # later sweeps overwrite with the freshest copy
                seen.add(it["id"])
            print(f"{label} sweep {sweep} page {page}/{pages} seen={len(seen)}/{total}", file=sys.stderr)
            page += 1
            time.sleep(0.3)
        if len(seen) >= total:
            return
        # a short sweep means items shifted while paging: go again, the merge fills the gaps
    print(f"WARNING: {label}: only {len(seen)} of {total} items seen", file=sys.stderr)


items = {}
for store in stores:
    for ch in CHANNELS:
        sweep_all({"Ebest-Channel": ch, "Current-Store-Id": store}, f"store{store}/{ch}", items)

print(f"total distinct items: {len(items)}", file=sys.stderr)
json.dump(list(items.values()), open(out, "w"), ensure_ascii=False)
