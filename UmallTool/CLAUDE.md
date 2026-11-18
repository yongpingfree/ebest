# goal

1, please extract all items from each of the URLs in reference into a CSV with item category, item name, price, available quantity
2, generate two python scripts
- script 1, extract data from URL using default browser (to avoid blocking python)
  - input to script 1 is the list of URLs (same as productList.md)
  - use use plain curl for the API calls, which wasn't blocked.
  - if two URLs does not have clear category or overlapping, just extract one by one, naming category name as the keywords in URL
- script 2, extract item category, item name, price, promotion price if any, available quantity from the output from script 1
  - input to script 2 is:
    - the output folder of script 1
    - a category mapping file like the categoryMapping.csv, so that code of category to be replaced by the actual meaning defined
  - if there are two item with exact same price and available category, only keep one in the final output
  - for the product price, use market_price if it is not 0, otherwise use price
  - default output filename is umall_items_ddMMMyyyy.csv
3, generate a wrapper script to run both script 1 and script 2 with default input file and folder, the script should be executable in Mac with one click

# reference

1, URL list
productList.md


2, sample price

   "price": 139,
   "market_price": 0,

3, update script 2
- if there's no promotion but there are differnece (excluding 0) in price, market_price, and pcs_price, use the lowest as promotion price (excluding 0), and highest and price


