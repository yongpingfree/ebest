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
