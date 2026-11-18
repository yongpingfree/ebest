#!/usr/bin/env python3
"""Fetch every item from minimall /app/api/v1/items (paged via x-total-pages header).
Usage: python3 fetch_all_items.py [out.json]"""
import json, sys, time, urllib.request

BASE = "https://minimall.donkibuy.com/app/api/v1/items"
out, page, pages, items = (sys.argv[1] if len(sys.argv) > 1 else "items.json"), 1, 1, []
while page <= pages:
    for attempt in range(4):
        try:
            with urllib.request.urlopen(f"{BASE}?page={page}", timeout=30) as r:
                pages = int(r.headers.get("x-total-pages", pages))
                data = json.load(r)
            break
        except Exception:
            if attempt == 3: raise
            time.sleep(2 ** attempt)
    items += data if isinstance(data, list) else data.get("items", data.get("data", []))
    print(f"page {page}/{pages} total={len(items)}", file=sys.stderr)
    page += 1
    time.sleep(0.3)
json.dump(items, open(out, "w"), ensure_ascii=False)
