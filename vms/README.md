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

## 说明

- 邮件验证码:`MAIL_MAILER=log` 时验证码写入 `storage/logs/laravel.log`,仅用于测试。
- 图片尺寸校验:封面 750×750、主图 750×750、详情图宽 375、分享海报宽 375 且高≤466,不符合会被拒绝。
- 首次上线前须确认的事项:Q10(是否同步库存默认值)、Q12(电子确认能否代替签名)、各分类/品牌 id 由运营在商品页补填。
