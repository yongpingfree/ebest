#!/usr/bin/env python3
"""Script 2: build a CSV (category, item name, price, promotion price,
available quantity) from the output folder of script 1.
Items with the same name, price, promotion price and quantity (e.g. listed
under overlapping categories) are kept once, under the most specific category (fewest items).

A category mapping file (lines of "code, name" or "code，name"; '#' lines and blanks ignored)
replaces the category code/keyword with its meaning. A category is looked up by
its keyword (e.g. "1549") then by its id; unmapped ones keep the keyword.

Usage: python3 script2_to_csv.py [input_dir] [category_mapping.csv] [output.csv]
Default output: umall_items_ddMMMyyyy.csv (e.g. umall_items_25Oct2026.csv)
Price is market_price when non-zero, else price. Prices are in AUD; the API returns cents.
With no activity_price, if price/market_price/pcs_price differ (ignoring 0), the lowest
becomes the promotion price and the highest the price.
"""
import csv
import json
import re
import sys
from datetime import date
from pathlib import Path


def load_mapping(path):
    mapping = {}
    for line in Path(path).read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # accept ASCII "," and full-width "，" (and "、"/tab) as separators
        parts = re.split(r"[,，\t]", line, maxsplit=1)
        if len(parts) == 2:
            mapping[parts[0].strip()] = parts[1].strip()
    return mapping


def main():
    in_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "output")
    mapping = load_mapping(sys.argv[2] if len(sys.argv) > 2 else "categoryMapping.csv")
    out_csv = sys.argv[3] if len(sys.argv) > 3 else f"umall_items_{date.today():%d%b%Y}.csv"
    rows, seen = [], set()
    files = [f for f in in_dir.glob("*.json") if f.name != "index.json"]
    datas = [json.loads(f.read_text(encoding="utf-8")) for f in sorted(files)]
    # smallest (most specific) categories first, so broad ones only add leftovers
    for data in sorted(datas, key=lambda d: len(d["items"])):
        category = mapping.get(data["category"]) or mapping.get(
            str(data.get("category_id")), data["category"])
        for it in data["items"]:
            promo = it.get("activity_price")
            base = it.get("market_price") or it["price"]  # market_price if non-zero
            if not promo:
                # no promotion: if price, market_price, pcs_price differ (ignoring 0),
                # lowest = promotion price, highest = price
                vals = {v for v in (it.get("price"), it.get("market_price"),
                                    it.get("pcs_price")) if v}
                if len(vals) > 1:
                    promo, base = min(vals), max(vals)
            promo = f"{float(promo) / 100:.2f}" if promo else ""
            row = [it["item_name"], f"{base / 100:.2f}", promo, it.get("store", 0)]
            if tuple(row) in seen:
                continue
            seen.add(tuple(row))
            rows.append([category] + row)
    with open(out_csv, "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.writer(fh)
        w.writerow(["category", "item_name", "price_aud", "promotion_price_aud", "available_quantity"])
        w.writerows(rows)
    print(f"{len(rows)} rows -> {out_csv}")


if __name__ == "__main__":
    main()
