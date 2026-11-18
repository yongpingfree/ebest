#!/usr/bin/env python3
"""Script 1: fetch item data for each URL in a URL list via plain curl.

Usage: python3 script1_fetch.py [productList.md] [output_dir]
Writes one raw JSON file per URL (<output_dir>/<keyword>.json) plus index.json.
"""
import json
import re
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import urlparse

API = "https://b.umall.com.au/api/h5app/wxapp/goods/items"
PAGE_SIZE = 20
# Same query the m.umall.com.au category page sends. "onsale,only_show" also returns
# out-of-stock (补货中) items, which the plain category_id query silently drops.
QUERY = "item_type=normal&is_point=false&approve_status=onsale%2Conly_show&goodsSort=1"
MAX_PAGES = 1000     # safety cap per category
EMPTY_RETRIES = 2    # re-request an empty page this many times before ending


def read_urls(path):
    return re.findall(r"https?://\S+", Path(path).read_text(encoding="utf-8"))


def parse_url(url):
    """Return (keyword, category_id) from the last path segment of a URL."""
    keyword = urlparse(url).path.rstrip("/").split("/")[-1]
    m = re.search(r"(\d+)(?:_\d+)?$", keyword)
    return keyword, (m.group(1) if m else None)


def curl_json(url, tries=4):
    """curl the API, retrying transient failures (network error, bad JSON)."""
    for attempt in range(1, tries + 1):
        try:
            out = subprocess.run(["curl", "-s", "-f", "-m", "30", url],
                                 capture_output=True, text=True, check=True).stdout
            return json.loads(out)["data"]
        except (subprocess.CalledProcessError, ValueError, KeyError):
            if attempt == tries:
                raise
            time.sleep(attempt)


def fetch_category(cat_id):
    """Keep loading pages until the whole category is retrieved.

    total_count is only reported on page 1. Pages can hold fewer than PAGE_SIZE
    rows (unavailable items are dropped after paging), so a short page is not the
    end. An empty page is re-requested a few times before it is trusted, and the
    walk continues past the end only if nothing new turns up. Items are de-duplicated
    by item_id in case pages shift while loading.
    """
    items, seen, page, total = [], set(), 1, None
    while page <= MAX_PAGES:
        for _ in range(EMPTY_RETRIES + 1):
            data = curl_json(f"{API}?page={page}&pageSize={PAGE_SIZE}&category={cat_id}&{QUERY}")
            if total is None:
                total = data["total_count"]
            if data["list"]:
                break
            time.sleep(1)
        if not data["list"]:
            break
        for it in data["list"]:
            key = it.get("item_id", id(it))
            if key not in seen:
                seen.add(key)
                items.append(it)
        page += 1
    if total and len(items) < total:
        print(f"  note: category {cat_id} returned {len(items)} of {total} "
              f"(total_count may include unavailable items)")
    return items, total


def main():
    url_file = sys.argv[1] if len(sys.argv) > 1 else "productList.md"
    out_dir = Path(sys.argv[2] if len(sys.argv) > 2 else "output")
    out_dir.mkdir(parents=True, exist_ok=True)
    index = []
    for url in read_urls(url_file):
        keyword, cat_id = parse_url(url)
        if cat_id is None:
            print(f"skip (no category id): {url}")
            continue
        try:
            items, total = fetch_category(cat_id)
        except (subprocess.CalledProcessError, ValueError, KeyError) as e:
            print(f"failed: {url} ({e})")
            continue
        (out_dir / f"{keyword}.json").write_text(
            json.dumps({"url": url, "category": keyword, "category_id": cat_id,
                        "total_count": total, "items": items},
                       ensure_ascii=False, indent=1), encoding="utf-8")
        index.append({"url": url, "category": keyword, "items": len(items)})
        print(f"{keyword}: {len(items)}/{total} items")
    (out_dir / "index.json").write_text(json.dumps(index, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
