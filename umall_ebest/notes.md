Step 2 files

- /report/2?key=<key> is reports/report2.php. It uses a separate key, REPORT2_KEY (default fghij).
- Report contents:
  - Date range, category (with All) and product (with All).
  - Overall status: the number of products where umall is lower, ebest is lower or the prices are equal. It uses each product's latest comparison inside the range.
  - A line chart of umall vs ebest unit price. With "All" selected, it plots the average across all matched products.
  - A detail table. A product appears once per load date, each row with its own load time.
- Daily job: compare:run --due is scheduled every minute and runs once per day, after 13:30 (COMPARE_START_HOUR=13 and COMPARE_START_MINUTE=30). It runs fetch_all_items.py, then match_products.py --extended, then loads the rows into price_comparison with a load_time. Run history goes into price_comparison_runs.
- Other new files: PriceComparisonService, RunPriceComparison, RunPriceComparisonCommand, the migration, and compare-tool/ (the three scripts plus the rules file).
- Config: I added the new settings to config/fileshare.php and .env.example, and added all the new files to the files array in fileupdate.sh.

Deployment steps

1. Run fileupdate.sh to copy the files to the server.
2. In .env, set REPORT2_KEY=<your key>. Set COMPARE_UMALL_DIR if the umall JSON files are not in storage/app/umall-json.
3. Put the umall JSON files in COMPARE_UMALL_DIR. The job fails with a "No umall json files found" error if the folder is empty.
4. Make sure the web/queue user can write to storage/app/compare, and that python3 can reach minimall.donkibuy.com.
5. Run the usual commands:
   - php artisan migrate
   - php artisan optimize:clear
   - php artisan queue:restart
6. Check that the scheduler cron (php artisan schedule:run every minute) and the queue worker are running. They already are if UM tracking works.
7. To test without waiting for 13:30, run php artisan compare:run. Then open https://52.62.119.114/report/2?key=<key>.

Two limits to know about. The job needs the umall JSON refreshed every day, which I assumed is done elsewhere. There is also no admin page or button for this job yet; only the artisan command and the schedule trigger it. Say if you want a button with run history like the UM tracking page.
Goal 10 fixes (matching_rules.json, match_products.py; copied to fileshare/compare-tool)

- Spec: a spec difference of more than 20% is no longer a match (max_spec_diff; this includes a case of 15 against a single bottle). Single packs under 500 g/ml must agree within 2.5% (small_pack: 350g and 360g are different, 104g and 106g are the same). Fresh produce keeps a looser 40% limit only when both sides have the same brand (produce_max_spec_diff, e.g. Driscoll's).
- Flavour and variant: if both titles say "X味", the flavours must agree. A word in flavor_words that appears on one side only (玫瑰, 低卡, 鸭脚, ...) makes it a different product. Pack counts (30pcs and 48pcs) and lengths (22.5cm and 20.5cm) must agree. protein (鸡/鸭/鱼...) must agree. Variety words were added for produce (珊瑚生菜, 油豆角, 旱黄瓜, ...).
- Missed matches: short titles are no longer capped at 0.3 similarity. Brand aliases (kerastase, pigeon, shiseido) were added. A same-brand, same-spec title check was added (same_brand_spec) for titles with different word order.
- Category: ingredient words (芝麻, 红豆, 茶 ...) count for less (category_weak_words). When the umall title category differs from the ebest category, the output uses the ebest category (category_conflict_use_ebest).
- Promotions: "5.99，三件8折", 买一送一, 满折, 满减 and 满赠 cannot be turned into a unit price. They are only listed, in the new columns umall promo note and ebest promo note. They appear in the report 2 detail table, the two higher-price CSV exports and the unmatched list and CSV. They do not change the compared price. The umall data only carries the tag (满折/满减/满赠, promotion_id); the discount wording itself is not in the JSON.

Known gaps: ebest items that are off sale (乐事 薯片, 卡诗 鎏光山茶花) are skipped by ebest_only_on_sale. The 花王 EMAL 洗衣液 pair has almost no shared title words. 思念 虾仁玉米水饺 400g and 300g differ by 25%, which the new rule treats as a different product.
