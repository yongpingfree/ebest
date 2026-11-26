#!/usr/bin/env python3
"""Convert umallfreedelivery.json to Excel: free delivery threshold amount, postal code, postal code name (suburb), state.

Names come from:
  1. `postcode_suburb_rules` in the JSON (suburb-specific amounts) - takes priority;
  2. otherwise the local postcode dataset (australian_postcodes.csv, Matthew Proctor's
     open dataset), one row per delivery-area locality, using the postcode's amount.
PO Box / LVR localities are ignored. Postcodes missing from the dataset get an empty name.
"""
import argparse, csv, json, os
from openpyxl import Workbook

def main():
    p = argparse.ArgumentParser()
    p.add_argument("input", nargs="?", default="umallfreedelivery.json")
    p.add_argument("-o", "--output", default="umallfreedelivery.xlsx")
    p.add_argument("--postcodes", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "australian_postcodes.csv"))
    a = p.parse_args()

    data = json.load(open(a.input, encoding="utf-8"))["data"]

    localities = {}
    states = {}
    if os.path.exists(a.postcodes):
        with open(a.postcodes, encoding="utf-8") as f:
            for r in csv.DictReader(f):
                if r["type"] in ("Post Office Boxes", "LVR"):
                    continue
                pc = r["postcode"].zfill(4)
                localities.setdefault(pc, set()).add(r["locality"].title())
                states.setdefault(pc, r["state"])

    # (postcode, name) -> amount
    out = {}
    for r in data["rows"]:
        amount = r.get("amount")
        if not amount:
            continue
        for pc in str(r.get("area") or "").split(","):
            pc = pc.strip()
            if pc:
                for name in sorted(localities.get(pc, [""])):
                    out[(pc, name)] = amount

    for r in data.get("postcode_suburb_rules", []):
        for pc in str(r.get("area") or "").split(","):
            pc = pc.strip()
            suburbs = r.get("suburbs") or []
            if not pc or not suburbs:
                continue
            for k in [k for k in out if k[0] == pc]:  # replaced by suburb-level rows
                del out[k]
            for s in suburbs:
                out[(pc, s["suburb"])] = s.get("amount", r.get("amount"))

    def state_of(pc):
        if pc in states:
            return states[pc]
        n = int(pc)  # fallback: standard postcode ranges
        for lo, hi, st in ((200, 299, "ACT"), (800, 999, "NT"), (1000, 1999, "NSW"), (2600, 2618, "ACT"),
                           (2900, 2920, "ACT"), (2000, 2999, "NSW"), (3000, 3999, "VIC"), (8000, 8999, "VIC"),
                           (4000, 4999, "QLD"), (9000, 9999, "QLD"), (5000, 5999, "SA"), (6000, 6999, "WA"),
                           (7000, 7999, "TAS")):
            if lo <= n <= hi:
                return st
        return ""

    wb = Workbook()
    ws = wb.active
    ws.title = "Free Delivery"
    ws.append(["Free delivery threshold amount", "Postal code", "Postal code name", "State"])
    for (pc, name) in sorted(out):
        ws.append([out[(pc, name)], pc, name, state_of(pc)])
        ws.cell(ws.max_row, 2).number_format = "@"  # keep leading zeros (e.g. 0800)
    for col, w in zip("ABCD", (32, 14, 28, 8)):
        ws.column_dimensions[col].width = w
    ws.freeze_panes = "A2"
    wb.save(a.output)
    print(f"{len(out)} rows -> {a.output}")

if __name__ == "__main__":
    main()
