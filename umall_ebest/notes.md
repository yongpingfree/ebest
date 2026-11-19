Step 2 files

- /report/2?key=<key> is reports/report2.php. It uses a separate key, REPORT2_KEY (default fghij).
- Report contents:
  - Product keyword search (title or SKU, several words allowed), date range, category (with All) and product (with All).
  - Overall status: products where umall is lower (red), ebest is lower (green) or equal, plus the number of umall and ebest products not matched. The two unmatched counts are clickable and list the products in the table below, with a button to go back to the comparison.
  - A line chart of umall (red) vs ebest (green) unit price. With "All" selected, it plots the average across all matched products.
  - A detail table: a product appears once per load, each row with its own load time. 售价 Umall/eBest is one field; the lower side is bold and in its colour. Promo notes are listed but not used in the price.
  - Hidden everywhere (table, chart, counts, dropdowns and CSV exports): any pair (umall sku + ebest sku) that has no entry in the latest load of the range, and any earlier entry whose category differs from the latest entry of the same umall product.
  - Four CSV downloads: umall higher, ebest higher, unmatched umall, unmatched ebest (all follow the current filters and the hiding rules).
- Category: ebest category when available; for umall-only products, the umall JSON filename translated to Chinese.
- Daily job: compare:run --due is scheduled every minute and runs once per day, after 13:30 (COMPARE_START_HOUR=13 and COMPARE_START_MINUTE=30). It runs fetch_all_items.py (never fetches umall), then match_products.py --extended, then loads the rows into price_comparison and price_comparison_unmatched with a load_time. Run history goes into price_comparison_runs. The UM tracking page has a button for the full job and a button that only redoes the comparison without re-fetching ebest.
- Other new files: PriceComparisonService, RunPriceComparison, RunPriceComparisonCommand, four migrations (000001 to 000005 in 2026_11_18), and compare-tool/ (the scripts plus the rules file). All are in the files array in fileupdate.sh.

Deployment steps

1. Run fileupdate.sh to copy the files to the server.
2. In .env, set REPORT2_KEY=<your key>. Optionally set COMPARE_START_HOUR / COMPARE_START_MINUTE, and COMPARE_UMALL_DIR if the umall JSON files are not in storage/app/umall-json.
3. Put the umall JSON files in COMPARE_UMALL_DIR. The job fails with a "No umall json files found" error if the folder is empty.
4. Make sure the web/queue user can write to storage/app/compare, and that python3 can reach minimall.donkibuy.com.
5. Run the usual commands:
   - php artisan migrate
   - php artisan optimize:clear
   - php artisan queue:restart
6. Check that the scheduler cron (php artisan schedule:run every minute) and the queue worker are running. They already are if UM tracking works.
7. On the UM tracking page, use the "Update comparison only" button once (no ebest re-fetch) so the new columns and categories are loaded, or run php artisan compare:run. Then open https://52.62.119.114/report/2?key=<key>.

Limit: the job needs the umall JSON refreshed every day, which is assumed to be done elsewhere.

Goal 10 fixes (matching_rules.json, match_products.py; copied to fileshare/compare-tool)

- Spec: a spec difference of more than 20% is no longer a match (max_spec_diff; this includes a case of 15 against a single bottle). Single packs under 500 g/ml must agree within 2.5% (small_pack: 350g and 360g are different, 104g and 106g are the same). Fresh produce keeps a looser 40% limit only when both sides have the same brand (produce_max_spec_diff, e.g. Driscoll's).
- Flavour and variant: if both titles say "X味", the flavours must agree. A word in flavor_words that appears on one side only (玫瑰, 低卡, 鸭脚, ...) makes it a different product. Pack counts (30pcs and 48pcs) and lengths (22.5cm and 20.5cm) must agree. protein (鸡/鸭/鱼...) must agree. Variety words were added for produce (珊瑚生菜, 油豆角, 旱黄瓜, ...).
- Missed matches: short titles are no longer capped at 0.3 similarity. Brand aliases (kerastase, pigeon, shiseido) were added. A same-brand, same-spec title check was added (same_brand_spec) for titles with different word order.
- Category: ingredient words (芝麻, 红豆, 茶 ...) count for less (category_weak_words). When the umall title category differs from the ebest category, the output uses the ebest category (category_conflict_use_ebest).
- Promotions: "5.99，三件8折", 买一送一, 满折, 满减 and 满赠 cannot be turned into a unit price. They are only listed, in the new columns umall promo note and ebest promo note. They appear in the report 2 detail table, the two higher-price CSV exports and the unmatched list and CSV. They do not change the compared price. The umall data only carries the tag (满折/满减/满赠, promotion_id); the discount wording itself is not in the JSON.

Known gaps: ebest items that are off sale (乐事 薯片, 卡诗 鎏光山茶花) are skipped by ebest_only_on_sale. The 花王 EMAL 洗衣液 pair has almost no shared title words. 思念 虾仁玉米水饺 400g and 300g differ by 25%, which the new rule treats as a different product.

## Goal 10 issue 4 (category)
- 已匹配商品：始终使用 ebest 的类别（category_name 对应的 group），ebest 无类别时才用 umall。
- umall 未匹配商品：使用 umall json 文件名的中文类别（`umall_file_categories`，前缀匹配）；文件名为纯数字（1370、1481、1499、1884、2337）的暂无法翻译，仍按标题关键词归类，其余为“其他”。
- /report/2：同一 umall 商品若在最新一次加载中类别发生变化，之前旧类别的记录不再显示；在最新一次加载中不存在的商品对不显示。
