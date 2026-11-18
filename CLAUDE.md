# your role

apps developer

# task

1, fix issues or import the fileshare application
2, generate admin guide
- use chinese
- URL: https://52.62.119.114/admin/
- login
- user management
- upload files
- pdf parameter settings
- all steps should be GUI only, no command no debugging
- put relevant screenshot from screenshots.pptx
3, generate user guide
- use chinese
- login URL https://52.62.119.114/app
- download files
- open pdf with password
- note on expiry date
- all steps should be GUI only, no command no debugging
- put relevant screenshot from screenshots.pptx

4, generate status report (refer to status section)
- this is an executive summary in word format
- list achievement with key screenshots
- list dependencies
- list next plan

5, build sample api stack
- API path is apptest/api/v1/items/{itemid}
- enforce authentication if User-Agent does not start with okhttp or X-Requested-With is not 'com.donkibuy.ebest'
- sample response message in api folder

6, generate requirement documentation on onboardingSystem.md
- output is Word document
- information required for PO
  供货商名称           
    purchase date           
    purchaser           
    marketing mode            
    预计到货时间            
    是否同步库存            
            
    PRODUCT NAME  SKU BARCODE QTY unit price (inc.GST)  GST rate  subtotal
    refer to PO template file
- if it's a new vendor, vendor needs to fill in registration info in the portal, and information to be sent to eBest backend for new vendor form submission:
    refer to new vendor form
- keep description in Chinese except for command/script output etc., don't include English
- avoid wording like:
  - • 全文为纯中文描述
- issues on first version:
  - the new system needs to align with the existing PO process (refer to PO录入流程&审核 document)
  - 库存问题，我们现在有三套库存，oms，wms，runbow，三个地方都有库存，数据一致性是不是要有一个统一的标准
    - this is only for the inventory under the vendor onboarding system
  - 然后原有的送货来了之后，要在wms录入po单，库存数量才能增加，这也是个问题，比如是否有自动创建po的功能？
    - 对于vendor delivery, vendor confirmed ready for sell, vendor create self PO by himself
    - for normal eBest delivery, once stock confirmed by eBest upon receival, vendor create PO for eBest to signoff
    - for JIT delivery, everyday upon delivery to eBest warehouse, vendor create PO for eBest to signoff
- add few more questions to the questions list
  - if there's customer compliant on vendor's product, should we divert the complain to vendor? vendor needs to have 24/7 team to handle the compliant

7, check the eBest供应商上架系统需求规格说明书.docx and compare with existing code in ows and wms, specify all integration required.
- there should be no integration with any other systems except oms and wms, if so, please list out

8, based on the current code based of oms and wms:
- generate a seperate Word document (not in spec docs) with the following information
- refer to integration-points.md (generated temporarily)
- list all integration points bebetween oms, amazon and wms
 - endpoint of each integration point
 - purpose
 - sample curl or command for such integration
 - required credential, and the configuration file and configuration item used
- for the vendor onboarding requirement:
 - list each new/updated integration points required in OMS/WMS

9, based on the fileshare source code, build a seperate entry point /report, so that
- /report/1?key=abcde entry point
 - supported by a landing php of report1.php
 - the code verify the key entry, if it pass, return 'Umall Data Tracking'
 - if failed, return Unauthorized
- add one function in admin to trigger the execution of script1_fetch.py and script2_to_csv.py, and also load the csv data to umall_tracking table with one addition colume of load_time
  - the button should be disabled if the admin user does not have a 'UM' permission
  - by default the job to be automatically triggered at 12:00pm (+/- one random value between 0 to 1 hr) every day, please keep a run history in the tracking page
  - change 'Umall tracking' to 'UM tracking'
  - don't show this under the feach & load data button:
    - Runs script1_fetch.py and script2_to_csv.py, then appends the CSV to the umall_tracking table with the load time.
    - reason why the button is diabled
- update the /report/1 page so that
 - there's first drop down box of category, and 2nd drop down box of product, 3rd drop down box of indicator, including price_aud, promotion_price_aud, available_quantity
 - next showing a line chart showing the indicator value over time
 - below the chart is a table with details of the selection in a table form
 - above the drop down menu add the following:
  - a start time and end time to narrow down the time range
  - title name search (can be like)
  - change type
  - new increase is only shown up if all category or several category is selected without specific title selected
  - not appearing today is only shown up if all category or several category is selected without specific title selected
  - refer to header.jpg (reference only)
  - for any comparison figure, it should be clickable, so the details will be shown up in the bottom table list
  - in the category, add one more selection for (All)
  - a CSV export button to export latest csv file generated by script 2 (in the dashboard page, not in fetch page)

10, build a umall ebest comparison page step by step
- input:
  sample umall and ebest product in umall_ebest folder
- step 1:
  - found out same item between umall and ebest according to:
    - category similar e.g. fruits, 水果 are same category
    - same keywords in title or short title
    - if products are from different brand, they should not be matched
      - for eBest product, brand is typically in first few words in the title, excluding 【】
    - if products are from different countries, they should not be matched
    - similar spec e.g. 1kg, 300g,  etc
    - unit price range within +/-50%
    - for same product with different weight, get unit price per kg or per g for comparison
    - wrong category
       饮品 12 cake 抹茶奥利奥泡芙 2枚装 约200g
    - sample correct match
      【原箱】中国秋月梨 Akizuki Pear Size 8 约3.5kg    【新鲜空运】中国莱阳秋月冰糖梨 1箱 7颗 约3.5kg
      澳洲Driscoll’s Jumbo蓝莓 Blueberry 约125g        Driscoll's 超大蓝莓 200g/盒
    - sample wrong match
       澳洲美人鱼蓝莓 Mermaid Blueberry 1盒 约125g  Driscoll's 超大蓝莓 200g/盒
       澳洲OzGroup Jumbo蓝莓 Blueberry 1盒 约125g   Driscoll's 超大蓝莓 200g/盒
       澳洲T&G Jumbo蓝莓 Blueberry 1盒 约125g      Driscoll's 超大蓝莓 200g/盒
       澳洲Royal Gala苹果 Royal Gala Apple 约1kg   中国红富士苹果 1kg
       本地白桃 约1kg                              新西兰杏子/杏桃 500g
       澳洲青苹果 Granny Smith Apple 约0.9–1kg   Cosmic Crisp 苹果 900~1000g
       新鲜白油桃 约0.9-1kg  96640 新西兰杏子/杏桃 500g
       #【整箱】喜茶 西柚绿妍果汁饮料 450ml*15瓶/箱 18320 【pack装】】维他 芒果味果汁 250ml*6 (wrong brand)
       整箱】三得利 乌龙茶 低糖 500ml*15瓶/箱     【整箱】三得利 玫瑰乌龙茶 无糖 500ml*15 (低糖 & 无糖不一样)
       12 cake 抹茶奥利奥泡芙 2枚装 约200g   奥利奥 可可脆卷 日式抹茶味 50g （different product)
       12 cake 抹茶奥利奥雪媚娘 2枚装 约200g  奥利奥 可可脆卷 日式抹茶味 50g (differrent product)
       【冻】广州酒家 利口福 红豆汤圆 10个入 200g 52364 利口福 莲蓉包 8个入 240g
       【冻】广州酒家 利口福 芝麻汤圆 10个入 200g 52363 利口福 莲蓉包 8个入 240g
       【冻】广州酒家 利口福 花生汤圆 10个入 200g 52362 利口福 莲蓉包 8个入 240g
       【冻】广州酒家 利口福 黑糯米汤圆 10粒入 200g  938 广州酒家 利口福 流沙凤凰汤圆200g 冷冻保存
       冻】明发 酒香海鲈鱼 500g  100718  MINGFA明发 鱼包蛋 600g
       冻】油炸豆腐皮 3pcs 45g 88302 【聚划算】【巨惠】超新鲜【弹口大粒虾滑】90%鲜虾比例！250g 终极版重磅登场！新鲜现做 全新包装！适合做汤，火锅，煎，包馄炖，饺子，酿豆腐 下面！冷链配送【Kirin Seafood】
       【冻】淘大 鲜虾云吞 104g  4487  淘大Amoy 咖喱鱼肉烧卖 140g
       【冻】盒马 黑豆冻豆腐 240g 115837  盒马 豆腐丸子 208g
        [冻】盒马工坊 全麦馒头 400g 116511  【聚划算】盒马工坊 酒酿饼 300g
        【冻】磨坊兄弟 包浆豆腐 185g 106609  【聚划算】雅方 火锅冻豆腐300g 冷链配送
        【冻】福源 和牛肉馄饨 220g  84197 福源 上海鲜肉馄饨 220g 冷冻保存
        【冻】福源 鲜肉粽 2粒入 560g  16546 福源 牛肉生煎包6pcs 230g
        冻】福源 鸡肉馄饨 220g  84194 福源 上海鲜肉馄饨 220g 冷冻保存
        【冻】福源 酸辣泡菜猪肉馄饨 220g 102607  福源 上海鲜肉馄饨 220g 冷冻保存

    - missed match


  - save the matching rule in a configuration file
  - build a python script to do the matching according to the matching rule, output to a csv file with columns of:
    - common category, umall product title, umall sku, ebest product title, ebest sku, umall unit price, umall unit, ebest unit price, ebest unit
    - for any price, if there's promotion or discounted price, use the lower price for comparison purpose
    - umall and ebest json files folder as input to the python rather than specified in the matching rule json
- step 2:
  - build a report page /report/2?key=<key>, update in the fileshare code base
  - add a seperate key
  - every day after 1pm, trigger the product extract from ebest (api/fetch_all_items.py), assuming umall is already there in storage/app/umall/script1_output/ subfolder
  - in the UM page, add one button to manually trigger this 1pm job (note: this job should never fetch any umall products); another button just update the comparision without re-fetch ebest products
  - do the comparison, and load into DB with load_time
  - the report has the following
    - data range
    - category (including All option)
    - product (including All option)
    - overall status
      # of umall price lower
      # of ebest price lower
    - line chart of price
    - list of details (for multiple dates, same product can list multiple times with load_time difference)
    - below the details, provide two buttons, to download products which umall has higher price, and products which ebest has higher price
  - list out the deployment steps


# status

1, 2026-11-2 to 2026-11-9
project name: eBest IT security enhancement

achivement:
- investigated inventory and delivery PDF document sharing process
- developed a mechanism to protect PDF document by password and expiry date
- developed a new platform for PDF document sharing process
- shared login credential with warehouse personal for testing

dependencies:
- still blocked by following 5 dependencies for security improvement on API and data export
1, source code of https://minimall.donkibuy.com/app/api/v1
2, LAB and Production environment access for https://minimall.donkibuy.com/app/api/v1
3, source codes of latest iOS and Android eBest App"
4, source code of EPR(中台)
5, access LAB and Production environment to EPP
- better to establish a weekly discussion with the development team

plan for next 5-7 days:
- continue investigation on white label
- continue investigation on Export menu security
- continue investigation on app/api/vi security

# input

1, the application is built on top of laravel
2, key features
- admin user can login and upload files
- normal user can login and download files
- for any pdf files uploaded by admin, a backend python script will be called for transformation


# issues/improvement

## after fixing any issue, update the files array in fileupload.sh script
## prompt the common commands to run after each upgrade, including:
  -  php artisan migrate
  -  php artisan optimize:clear
  -  php artisan queue:restart

1, the backend python should be called like below:

python3 transform.py <input pdf file> "user password" -o <output pdf file> --hours <validity hours> --owner-password "owner password"

-> in admin GUI, need to add the configuration for user password, owner password and validity hours
-> the change history should be maintained for these 3 items;
-> by default user password will be auto refreshed every date (cut off by mid night) unless manually updated by admin
-> owner password will be auto refreshed every week unless manually updated by admin
-> hours is 24 hours by default
-> when normal user login, in the file download page, the current PDF user password should be presented
-> the password under this context is only for PDF password, different from system login credentials

2, if admin drag and drop an entire folder, the folder structure should be maintained in shared files view
3.1, in the sharefolder page, if there are folder, the folder should be clickable, selectable.
if click a folder, go into the folder, and see the subfolders and files in side that folder

3.2, user is able to download individual files, or multiple files, entire folder, or a mix of folder and files; if multiple files/folders are selected for downloading, a zip file is downloaded, in the same way as Google Drive

4, transform.py issue

ubuntu@ip-172-31-200-201:/var/www/fileshare$ cat storage/logs/transform.log 
[2026-11-09 23:29:38] production.ERROR: PDF transform failed {"file":"1a_eBest撿貨單_ver3008.pdf","exit_code":1,"command":"transform.py /srv/fileshare/originals/1a_eBest撿貨單_ver3008.pdf <user-pw> -o /srv/fileshare/published/1a_eBest撿貨單_ver3008.pdf.part --hours 24 --owner-password <owner-pw>","stderr":"Traceback (most recent call last):
  File \"/opt/pdf-transform/transform.py\", line 156, in <module>
    main()
    ~~~~^^
  File \"/opt/pdf-transform/transform.py\", line 145, in main
    owner_pw, expiry = protect(args.pdf, out, args.password, args.hours, args.owner_password)
                       ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/transform.py\", line 100, in protect
    writer.add_js(build_js(expiry_s * 1000))
    ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_writer.py\", line 788, in add_js
    deprecation_with_replacement(\"add_js\", \"add_open_action\", \"7.0.0\")
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 483, in deprecation_with_replacement
    deprecation(
    ~~~~~~~~~~~^
        f\"{old_name} is deprecated and was removed in pypdf {removed_in}. Use {new_name} instead.\"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 470, in deprecation
    raise DeprecationError(msg)
pypdf.errors.DeprecationError: add_js is deprecated and was removed in pypdf 7.0.0. Use add_open_action instead.
","stdout":""} 
[2026-11-09 23:29:51] production.ERROR: PDF transform failed {"file":"1a_eBest撿貨單_ver3008.pdf","exit_code":1,"command":"transform.py /srv/fileshare/originals/1a_eBest撿貨單_ver3008.pdf <user-pw> -o /srv/fileshare/published/1a_eBest撿貨單_ver3008.pdf.part --hours 24 --owner-password <owner-pw>","stderr":"Traceback (most recent call last):
  File \"/opt/pdf-transform/transform.py\", line 156, in <module>
    main()
    ~~~~^^
  File \"/opt/pdf-transform/transform.py\", line 145, in main
    owner_pw, expiry = protect(args.pdf, out, args.password, args.hours, args.owner_password)
                       ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/transform.py\", line 100, in protect
    writer.add_js(build_js(expiry_s * 1000))
    ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_writer.py\", line 788, in add_js
    deprecation_with_replacement(\"add_js\", \"add_open_action\", \"7.0.0\")
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 483, in deprecation_with_replacement
    deprecation(
    ~~~~~~~~~~~^
        f\"{old_name} is deprecated and was removed in pypdf {removed_in}. Use {new_name} instead.\"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 470, in deprecation
    raise DeprecationError(msg)
pypdf.errors.DeprecationError: add_js is deprecated and was removed in pypdf 7.0.0. Use add_open_action instead.
","stdout":""} 
[2026-11-09 23:29:54] production.ERROR: PDF transform failed {"file":"1a_eBest撿貨單_ver3008.pdf","exit_code":1,"command":"transform.py /srv/fileshare/originals/1a_eBest撿貨單_ver3008.pdf <user-pw> -o /srv/fileshare/published/1a_eBest撿貨單_ver3008.pdf.part --hours 24 --owner-password <owner-pw>","stderr":"Traceback (most recent call last):
  File \"/opt/pdf-transform/transform.py\", line 156, in <module>
    main()
    ~~~~^^
  File \"/opt/pdf-transform/transform.py\", line 145, in main
    owner_pw, expiry = protect(args.pdf, out, args.password, args.hours, args.owner_password)
                       ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/transform.py\", line 100, in protect
    writer.add_js(build_js(expiry_s * 1000))
    ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_writer.py\", line 788, in add_js
    deprecation_with_replacement(\"add_js\", \"add_open_action\", \"7.0.0\")
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 483, in deprecation_with_replacement
    deprecation(
    ~~~~~~~~~~~^
        f\"{old_name} is deprecated and was removed in pypdf {removed_in}. Use {new_name} instead.\"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 470, in deprecation
    raise DeprecationError(msg)
pypdf.errors.DeprecationError: add_js is deprecated and was removed in pypdf 7.0.0. Use add_open_action instead.
","stdout":""} 
[2026-11-09 23:30:01] production.ERROR: PDF transform failed {"file":"1a_eBest撿貨單_ver3008.pdf","exit_code":1,"command":"transform.py /srv/fileshare/originals/1a_eBest撿貨單_ver3008.pdf <user-pw> -o /srv/fileshare/published/1a_eBest撿貨單_ver3008.pdf.part --hours 24 --owner-password <owner-pw>","stderr":"Traceback (most recent call last):
  File \"/opt/pdf-transform/transform.py\", line 156, in <module>
    main()
    ~~~~^^
  File \"/opt/pdf-transform/transform.py\", line 145, in main
    owner_pw, expiry = protect(args.pdf, out, args.password, args.hours, args.owner_password)
                       ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/transform.py\", line 100, in protect
    writer.add_js(build_js(expiry_s * 1000))
    ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_writer.py\", line 788, in add_js
    deprecation_with_replacement(\"add_js\", \"add_open_action\", \"7.0.0\")
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 483, in deprecation_with_replacement
    deprecation(
    ~~~~~~~~~~~^
        f\"{old_name} is deprecated and was removed in pypdf {removed_in}. Use {new_name} instead.\"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 470, in deprecation
    raise DeprecationError(msg)
pypdf.errors.DeprecationError: add_js is deprecated and was removed in pypdf 7.0.0. Use add_open_action instead.
","stdout":""} 
[2026-11-09 23:30:01] production.ERROR: PDF transform failed {"file":"1a_eBest撿貨單_ver3008.pdf","exit_code":1,"command":"transform.py /srv/fileshare/originals/1a_eBest撿貨單_ver3008.pdf <user-pw> -o /srv/fileshare/published/1a_eBest撿貨單_ver3008.pdf.part --hours 24 --owner-password <owner-pw>","stderr":"Traceback (most recent call last):
  File \"/opt/pdf-transform/transform.py\", line 156, in <module>
    main()
    ~~~~^^
  File \"/opt/pdf-transform/transform.py\", line 145, in main
    owner_pw, expiry = protect(args.pdf, out, args.password, args.hours, args.owner_password)
                       ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/transform.py\", line 100, in protect
    writer.add_js(build_js(expiry_s * 1000))
    ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_writer.py\", line 788, in add_js
    deprecation_with_replacement(\"add_js\", \"add_open_action\", \"7.0.0\")
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 483, in deprecation_with_replacement
    deprecation(
    ~~~~~~~~~~~^
        f\"{old_name} is deprecated and was removed in pypdf {removed_in}. Use {new_name} instead.\"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File \"/opt/pdf-transform/venv/lib/python3.14/site-packages/pypdf/_utils.py\", line 470, in deprecation
    raise DeprecationError(msg)
pypdf.errors.DeprecationError: add_js is deprecated and was removed in pypdf 7.0.0. Use add_open_action instead.
","stdout":""} 
ubuntu@ip-172-31-200-201:/var/www/fileshare$ 

5,
pypdf.errors.DependencyError: cryptography>=3.1 is required for AES algorithm
6, transform.py the expiry only shows up in Adobe, not in browser
the fix should be only on transform.py, not others
7, hide filament in dashboard
8, there should be 3 types of user
- admin user: able to do user management and upload files
- operator user: able to upload files, but no user management access
- normal user: able to download files only
- user credential should be cached in browser, so no need to input again next time
9, browser does not save credential
10, in user management Create User page, role list is not there
11, in user management, add a column showing last login time
12, operator is able to access Users 
13, the 'Users' menu should be hidden for operator
14, password of normal user is not saved to DB, and not able to login after save the password; admin and operator works fine
15, in admin login landing page, add a menu option to jump to /app
16, in /app landing page, if the login user is admin or operator, add a menu option to jump to /admin, but this option should not be visible to normal user
17,
ubuntu@ip-172-31-200-201:/var/www/fileshare$ php artisan optimize:clear

   UnexpectedValueException 

  Invalid route action: [App\Filament\Auth\AppLogin].

  at vendor/laravel/framework/src/Illuminate/Routing/RouteAction.php:92
     88▕      */
     89▕     protected static function makeInvokable($action)
     90▕     {
     91▕         if (! method_exists($action, '__invoke')) {
  ➜  92▕             throw new UnexpectedValueException("Invalid route action: [{$action}].");
     93▕         }
     94▕ 
     95▕         return $action.'@__invoke';
     96▕     }

      +31 vendor frames 

  32  [internal]:0
      Illuminate\Foundation\Application::{closure:Illuminate\Foundation\Application::boot():1139}()
      +6 vendor frames 

  39  artisan:16
      Illuminate\Foundation\Application::handleCommand()
 18, add an Export button in user list
 - add an Export button in user list
 - the visibility on Export button is controlled by permission
 - a list of user permission can be seen as settings/permissions.json
 - the permission for Export button should be configurable
 19, for admin and operator user, list history of user password in the past 3 days, in both upload files and downloaded files
20, in Upload Files sheet, the Drag & drop files area is too small, also background is same as other space, which is not clear to user.
- change background color
- add an icon for easy understanding
- add some border
21, in the admin dashboard, show a line chart with total number of files uploaded, and downloaded, and total number of times of download every day in the past 30 days.
22, in download file, the folder is in grey color, change it to yellow
23, the file icon is also grey, please change icon as Excel file for xls and xlsx, icon as Pdf for pdf file
24, for any Excel file uploaded
- protect it by a password, and a similar expiry date by VBA script; using the same configuration (password and expiry hours) and same python script
- the python script protect file according to suffix (pdf and xls/xlsx)
- change PDF setting to PDF/Excel setting
- change PDF password to PDF/Excel password
25, got error message on xlsx transformation: Excel output must end with .xlsm (macros cannot live in a .x...
26, build a python script
- input: path of an image locally
- job: upload the file to S3 bucket by <uuid>-<file> the uuid to be generated randomly
- sample code:
import boto3, uuid
s3 = boto3.client("s3", region_name="ap-southeast-2")
CDN_HOST = "cdn.minimall.donkibuy.com"
key = f"images/{uuid.uuid4()}-{filename}"
s3.upload_file(local_path, BUCKET, key,
               ExtraArgs={"ACL": "public-read", "ContentType": content_type})
public_url = f"https://{CDN_HOST}/{key}"