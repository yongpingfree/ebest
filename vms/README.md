# eBest VMS(供应商管理系统)

独立的 Laravel 应用,入口 `/vms`。第 1 阶段不依赖 OMS/WMS 的任何改动:通过 Excel 导出由运营手工导入,再回填 WMS 采购单号。

## 功能(goal 1)

| 功能 | 供应商入口 | 运营入口 |
|---|---|---|
| 注册 + 邮箱验证码 | `/vms/register`、`/vms/verify` | — |
| 供应商资料(参照新供应商表)提交、修改、审核 | `/vms/profile` | `/vms/staff/vendors` |
| 商品录入(全部 import-items 字段)+ 图片上传 + 草稿/提交/退回 | `/vms/items` | `/vms/staff/items` |
| 导出 import-items.xlsx | 商品列表/详情 | 商品列表(可多选) |
| 采购单(三种配送方式)+ 校验 + 导出 | `/vms/pos` | `/vms/staff/pos` |
| 状态查看(商品、采购单、供应商,均有历史) | 各详情页 | 各详情页 |

关键规则已实现:银行账号加密存储且界面掩码、仅 admin 可查看完整内容并写审计日志;采购单只能选「已上架」商品;虚拟库存商品自动 999999/0;同商品单价与上次不同须填标注;营销模式须与商品一致;供应商配送无需审核,其他由运营按实际到库数量审核(不一致即异常)。

所有数据库表以 `vms_` 开头(`DB_PREFIX=vms_`,含 sessions/cache/jobs/migrations)。

## 目录

- `config/vms.php`:商品字段、图片规格、配送方式的唯一定义(驱动表单、校验、导出)
- `app/Services/`:ItemService(校验)、ImageService(图片)、ExportService(xlsx)、PurchaseOrderService
- `resources/templates/import-items.xlsx`:导出所用模板(列顺序与 OMS 一致)
- 日后对接 OMS/WMS 的适配层放 `app/Integration/`(尚未创建)

## 部署步骤

1. 环境:PHP 8.3(含 zip、gd、mbstring、pdo_mysql/sqlite 扩展)、Composer、MySQL(或 SQLite)、Nginx。
2. 上传代码到服务器,例如 `/var/www/vms`,进入目录:
   - `composer install --no-dev --optimize-autoloader`
   - `cp .env.example .env`,然后 `php artisan key:generate`
3. 编辑 `.env`:`APP_URL`、数据库、邮件(`MAIL_*`)、`VMS_STAFF_EMAIL/VMS_STAFF_PASSWORD`。
   - 图片:测试用 `VMS_IMAGE_DISK=public`;生产用 `s3`,并填写 `AWS_*`(最小权限账号,只允许 `images/` 前缀)和 `VMS_IMAGE_CDN_HOST`。
4. `php artisan migrate --force`
5. `php artisan db:seed --force`(创建第一个 admin 员工账号);之后可用 `php artisan vms:create-staff 邮箱 姓名 --role=operator` 增加运营账号。
6. `php artisan storage:link`(`public` 图片盘需要)
7. 权限:`storage` 与 `bootstrap/cache` 目录对 web 用户可写。
8. Nginx:站点根目录指向 `vms/public`(建议独立域名);`location / { try_files $uri /index.php?$query_string; }`,PHP 走 fastcgi。
   若与其他应用共用域名,须同时转发 `/vms`、`/css`、`/images`、`/storage` 到本应用。
9. 每次升级后执行:`php artisan migrate --force`、`php artisan optimize:clear`、`php artisan queue:restart`

## goal 3 更新(语言、品牌、分类、供应商导出、审核邮件)

### 新增配置(`.env`)

| 配置 | 说明 |
|---|---|
| `APP_LOCALE=zh`、`APP_FALLBACK_LOCALE=zh` | 默认中文;**回退语言必须是 zh**,否则缺少翻译时会错误地显示英文 |
| `VMS_STAFF_NOTIFY_EMAIL` | 新供应商提交资料后通知的审核邮箱(逗号分隔);不填则通知全部启用的管理员 |
| `VMS_CDN_DISTRIBUTION_ID` | 可选。CloudFront 分配 id;配置后删除图片会同时让 CDN 缓存失效(IAM 需 `cloudfront:CreateInvalidation`) |
| `MAIL_*` | 审核通知邮件与验证码邮件都走该配置,生产环境不能用 `log` |

### 部署

1. 运行 `./fileupdate.sh` 上传文件。
2. 服务器:`php artisan migrate --force`(新增 `vms_brands`、`vms_categories` 表和 `vms_vendors.submit_notified_at`)、`php artisan optimize:clear`、`php artisan queue:restart`。
3. 载入分类(首次及分类变更时):
   1. 在 OMS 生产库执行 `database/oms/export_categories.sql`,结果导出为带表头的 UTF-8 CSV(列:id,parent_id,name_zh,name_en,status,position);
   2. 放到服务器 `storage/app/categories/categories.csv`;
   3. 运行 `php artisan vms:load-categories`(可加 `--prune` 删除 CSV 中已不存在的分类;也可指定路径 `php artisan vms:load-categories /path/x.csv`)。仅 `status=1` 的分类会出现在供应商下拉里。

### 验证点

| # | 功能 | 验证步骤 | 预期 |
|---|---|---|---|
| 1 | 中英文切换 | 打开 `/vms/login` 和 `/vms/register`,点右上角「English」;进入各菜单页 | 菜单、表单标签、按钮、校验提示、状态、验证码邮件均为英文;再点「中文」切回;刷新或换页后语言保持 |
| 2 | 运营端保持中文 | 打开 `/vms/staff` 各页 | 始终中文,且无语言切换按钮 |
| 3 | 图片删除 | 编辑商品,删除一张图片;再重新上传 | 页面提示已删除;S3 桶中该 `images/<uuid>-<file>` 已不存在(配置了 `VMS_CDN_DISTRIBUTION_ID` 时 CDN 也失效);重新上传成功。S3 删除失败时图片记录保留并提示错误 |
| 4 | 注册必须有品牌 | 新供应商在「供应商资料」不添加品牌就提交 | 被拒绝并提示「请至少添加一个品牌并上传品牌图片后再提交」;添加品牌并上传图片后可提交 |
| 5 | 品牌管理 | 供应商菜单「品牌管理」添加、改名、换图、删除品牌 | 可操作;换图后旧图被物理删除;品牌已被商品使用或已有 eBest 编号时不能删除;有编号后名称不可改 |
| 6 | 回填品牌编号 | 运营端菜单「品牌」填写品牌编号 | 保存成功,供应商端「eBest 品牌编号」显示该值;商品下拉显示「编号-名称」 |
| 7 | 导出供应商 | 运营(admin)端「供应商审核」勾选多个供应商,点「导出所选」 | 下载 CSV:每个供应商一行,**最后一行是 `INSERT INTO suppliers ... VALUES (...), (...)`**;可在 WMS 库执行;非 admin 看不到该按钮;产生审计日志 |
| 8 | 审核通知邮件 | 新供应商注册、验证邮箱、填写资料并提交 | 收件人(`VMS_STAFF_NOTIFY_EMAIL` 或全部管理员)收到「新供应商注册待审核」邮件,含审核链接;邮件发送失败不影响提交(见 `storage/logs/laravel.log`) |
| 9 | 商品分类联动 | 新增商品,在「分类与品牌」选择品牌、分类、子分类 | 品牌下拉显示「id-名称」(只含本供应商品牌;无编号时显示 `V<VMS编号>`);选分类后子分类自动刷新;三项提交时必填 |
| 10 | 导出带品牌 id | 对已回填品牌编号的商品导出 import-items.xlsx | `brand_id` 列为 eBest 品牌编号,`category_id` 列为所选子分类 id |
| 11 | 分类载入 | 按上面第 3 步载入 | 命令输出载入条数和一级分类数;重复运行不产生重复数据 |

### 问题修复(商品图片、上架后修改)

| # | 内容 | 验证步骤 | 预期 |
|---|---|---|---|
| 1 | 图片可点击查看 | 商品详情页、编辑页、运营端商品页点击任一图片 | 页面内弹出大图,显示图片类型、尺寸、文件名;可「查看原图」;← → 切换、Esc 关闭 |
| 2 | 删除后仍可访问 | 删除一张图片后访问它的 URL | S3 文件已删除;CDN 缓存需要 IAM 权限才能清除(见下)。清除失败时页面提示「CDN 缓存暂未清除」,并在 `laravel.log` 记录 AccessDenied |
| 3 | 上架后修改 | 把商品标为「已导入 OMS/已上架」后,供应商打开该商品点「修改标题/图片」 | 只能改中文标题、英文标题、短标题和图片;其他字段不可改;必填图片不能删光(须先上传替换);修改后运营端列表出现「上架后有修改」标记,商品页可点「已同步,清除标记」 |
| 4 | 上架后替换图片,旧图未从 CDN 清除 | 对已上架商品重新上传封面图/SKU 图(单图类型上传即替换旧图);或删除多图中的一张再上传 | 旧图文件从 S3 删除并让 CDN 失效;若 IAM 权限不足,页面提示「CDN 缓存暂未清除」,`laravel.log` 有 AccessDenied;品牌换图同理 |
| 5 | 预售字段 | 新增/编辑商品,「销售与配送」分组 | 「预售结束时间」标签为「悉尼堪培拉时区」;结束时间用日期时间控件,「预售可派送最早/最晚日期」用日历控件(不再是自由文本);保存后导出 xlsx 中日期为 `2026-12-01`、时间为 `2026-12-01 18:00`;旧的自由文本值若格式不符,编辑时显示为空需重新选择 |
| 6 | 已通过供应商改名后,运营端看不到待审核 | 已通过的供应商在「供应商资料」修改名称并提交;运营端打开概览点「待审核供应商」,或在「供应商审核」选「待审核」 | 列表能看到该供应商,名称下方显示「待审核改名为:新名称」,状态旁有「有修改待审」标记;详情页「待审核的修改内容」用中文字段名对照新旧值;通过/驳回后标记消失 |

**CDN 清除权限(问题 2)**:`.env` 中 `VMS_CDN_DISTRIBUTION_ID` 对应的 AWS 用户(日志中为 `ebest-staging`)必须有 `cloudfront:CreateInvalidation`。在 IAM → 该用户 → 添加内联策略:

```json
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"cloudfront:CreateInvalidation","Resource":"arn:aws:cloudfront::<账号ID>:distribution/<分配ID>"}]}
```

加好后无需改代码,重新删除一张图片即可验证;失效通常 1–5 分钟内全球生效。

### 已知限制

- 「供应商自行新建分类/子分类」未实现,分类只能从 OMS 导出的数据中选择。
- 员工在运营端填写的退回原因、备注等是自由文本,在供应商端英文界面里仍显示原文(不翻译)。
- 此版本在无 PHP 环境下编写,**尚未运行**,部署后请逐项按上表验证。

## 说明

- 邮件验证码:`MAIL_MAILER=log` 时验证码写入 `storage/logs/laravel.log`,仅用于测试。
- 图片尺寸校验:封面 750×750、主图 750×750、详情图宽 375、分享海报宽 375 且高≤466,不符合会被拒绝。
- 首次上线前须确认的事项:Q10(是否同步库存默认值)、Q12(电子确认能否代替签名)、各分类/品牌 id 由运营在商品页补填。
