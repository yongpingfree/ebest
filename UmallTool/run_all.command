#!/bin/bash
# One-click wrapper (double-click in Finder): runs script 1 then script 2
# with the default input file and folders.

cd "$(dirname "$0")" || exit 1

URL_LIST="productList.md"
RAW_DIR="script1_output"
MAPPING="categoryMapping.csv"
OUT_CSV="umall_items_$(date +%d%b%Y).csv"

echo "== Script 1: fetching items from $URL_LIST -> $RAW_DIR"
python3 script1_fetch.py "$URL_LIST" "$RAW_DIR" || { echo "Script 1 failed"; read -n 1 -s -r -p "Press any key to close..."; exit 1; }

echo
echo "== Script 2: building $OUT_CSV (mapping: $MAPPING)"
python3 script2_to_csv.py "$RAW_DIR" "$MAPPING" "$OUT_CSV" || { echo "Script 2 failed"; read -n 1 -s -r -p "Press any key to close..."; exit 1; }

echo
echo "Done: $(pwd)/$OUT_CSV"
read -n 1 -s -r -p "Press any key to close..."
