Step 2 files

- /report/2?key=<key> is reports/report2.php. It uses a separate key, REPORT2_KEY (default fghij).
- Report contents:
  - Date range, category (with All) and product (with All).
  - Overall status: the number of products where umall is lower, ebest is lower or the prices are equal. It uses each product's latest comparison inside the range.
  - A line chart of umall vs ebest unit price. With "All" selected, it plots the average across all matched products.
  - A detail table. A product appears once per load date, each row with its own load time.
- Daily job: compare:run --due is scheduled every minute and runs once per day, after 13:00 (COMPARE_START_HOUR). It runs fetch_all_items.py, then match_products.py --extended, then loads the rows into price_comparison with a load_time. Run history goes into price_comparison_runs.
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
7. To test without waiting for 13:00, run php artisan compare:run. Then open https://52.62.119.114/report/2?key=<key>.

Two limits to know about. The job needs the umall JSON refreshed every day, which I assumed is done elsewhere. There is also no admin page or button for this job yet; only the artisan command and the schedule trigger it. Say if you want a button with run history like the UM tracking page.