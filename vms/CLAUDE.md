# goal

1, implement a framework with the following feature:
- entry point is /vms
- support new vendor self registration, with email confirmation code
- support new item onboarding, including all required fields (mandatory or optional), and images uploading
- support export to import-items.xlsx
- support new PO document
- support export of new PO document
- support status viewing of new item and PO

2, based on the current implement, I need to provide a MVP version for friendly vendor and internal team to test, please suggest:
- a MVP scope and boundaries
- assuming no change in OMS/WMS would be possible, so please highlight any manual integratio steps
- all detailed steps/development to achive the MVP within 3 days
- a slide desk showing each step vendor/option needs to go through from vendor onboarding till successful product delivery

3, make the following updates
- a language toggle for Chinese and English for /vms and /vms/register entry
  - all menu and input files in /vms should support both  Chinsee and English
  - /vms/staff remain as Chinese by default
- vendor is able to delete an uploaded image and re-upload, the deleted image should be physically removed from cdn at same time
- for new vendor registration, enforce vendor to create at least one brand, and upload brand image
- in the /vms, add one brand management menu
- for all new Brand, eBest staff to fill in the brand ID created in WMS
- when exporting vendor, options to do multiple select, and last record is the SQL for inserting to suppliers table (refer wms_suppliers.sql)
- after a new vendor registration, email eBest staff for approval
- when creating a new item, vendor can select:
  - brand from drop down menu (showing id-name)
  - category (id-name)
  - subcategory (auto refreshed with selection of category)
- create one SQL to export category and subcategory from all items, including id and name
- create one script to load the category and subcategory into vms internal db, assuming the CSV in predefined folder
- for all implementation, update README.md for verification points

# issues
1, in the product item view, the image should be clickable so user can see details
2, after deleting an image, it still can be accessed from URL

[2026-11-27 18:40:34] production.ERROR: Error executing "CreateInvalidation" on "https://cloudfront.amazonaws.com/2020-05-31/distribution/EQBQSAG176B64/invalidation"; AWS HTTP error:
AccessDenied (client): User: arn:aws:iam::730335262564:user/ebest-staging is not authorized to perform: cloudfront:CreateInvalidation on resource: arn:aws:cloudfront::730335262564:distribution/EQBQSAG176B64 because no identity-based policy allows the cloudfront:CreateInvalidation action {"userId":2,"exception":"[object] (Aws\\CloudFront\\Exception\\CloudFrontException(code: 0): Error executing \"CreateInvalidation\" on \"https://cloudfront.amazonaws.com/2020-05-31/distribution/EQBQSAG176B64/invalidation\"; AWS HTTP error:
AccessDenied (client): User: arn:aws:iam::730335262564:user/ebest-staging is not authorized to perform: cloudfront:CreateInvalidation on resource: arn:aws:cloudfront::730335262564:distribution/EQBQSAG176B64 because no identity-based policy allows the cloudfront:CreateInvalidation action at /var/www/vms/vendor/aws/aws-sdk-php/src/WrappedHttpHandler.php:204)

3, for onboarded item, allow vendor to modify limited fields: title, images
4, for onboarded item, when replacing an image, the old image is not deleted from CDN
5，in the onboarding page
- change 墨尔本时区 to 悉尼堪培拉时区
- 预售可派送最早/晚日期 用calendar widget, not free text input
6, after an approved vendor changed his name, eBest staff seeing an pending approval, but in the vendor audit, nothing shown up
7, bar code field is not editable in PO creation; also quantity and unit price input fields not aligned with field name in the PO creation page

# to do
0， (done) support chinese/english
1, (done)make sure any uploaded image can be deleted
2, (done)for new vendor registration, one brand to be created as mandatory
3, (done)in ventory management portal, add option to manage Brand and upload images
4, (done)download from a list of category and subcategory from oms
5, (done)in the vendor onboarding, when vendor create a new item, option to select category and subcategory (from drop down manual), or create new category, subcategory
6, (done) when exporting vendor, options to do multiple select, and last record is the SQL for inserting to suppliers table (refer wms_suppliers.sql)
7, (done) after a new vendor registration, email eBest staff for approval
8, (defered) where to update sellable item?
9, (done) date input use widget, instead of free text
10, PO to notifiy eBest: 1) vendor self delivery, no approval required; 2) other 2 type, approval required. in any case, eBest need to import to WMS and update WMS ID.
11, 3 type of eBest personal: 1) approval vendor; 2) approve new item; 3) approve new PO
12, verify format of ';' in the free text field in new item
13, check DB connection from fileserver (for integration purpose)
14, (fixed) fix the bar code in new PO page
15, create a demo

# notes on sellable quantity
可售数量怎么形成

1. 审核采购单时,WMS 会检查 available_qty 是否等于收货明细合计,不一致则报错"收货数量与订单数量不符"。
2. 审核通过后,WMS 调用 updatePOStock,按条码加到 WMS 自己的 stocks 表,并写一条 stock_logs(note 为 po)。
3. 定时任务 syncPOtoOMS 把已审核且 syncback=0 的采购单行推给 OMS 的 batch_update_quantity_v3:
   - 推送的数量是 available_qty,是增量,并不是库存绝对值。
   - OMS 做的是 sku.quantity = 旧库存 + 新增量(stock_keeping_units.rb:27)。
   - allow_sync 不是 Y 或 OMS 时,数量按 0 推送,只更新进价。
   - 推送成功后采购单行的 syncback 置 1,防止重复加库存。
4. 所以 OMS 的 sku.quantity 是该 SKU 所有采购单入库量的累计结果,再被订单扣减。每个 SKU 只有一个库存数字。

已售数量怎么形成

- 下单时 OMS 在 after_create 中执行 decrease_inventory!,直接减 sku.quantity(order.rb:327、stock_keeping_unit.rb:250)。
- 同时执行 increase_sales_count!,加到商品(item)级别的 sales_count。取消订单时 decrease_sales_count! 回退,退款或售后会把库存加回。
- sales_count 是商品级累计数,不分采购单,也不分供应商。
- OMS 订单行里没有采购单号。WMS 的订单拣货和 stocks 也只按条码记数量,不记来自哪张采购单。

对 VMS 的影响

1. 按采购单的已售数量,在 OMS 和 WMS 中都查不到。 VMS 需要自己按先进先出(FIFO)分摊,这正是我上一轮方案里的做法。
2. 销量数据来源: OMS 订单行(order_items)有 SKU、数量和订单日期,是可靠来源。sales_count 太粗,不能用。MVP 阶段由运营导出订单行文件上传;第 2 阶段由 goal 12 第 1 项的只读接口提供。
3. 库存重复入账风险: batch_update_quantity_v3 是增量更新。如果 VMS 以后用它推送供应商配送采购单,同时 WMS 又处理同一张单,库存就会加两次。VMS 计算出的可售数量也只能当"参考值",MVP 里由运营手工更新 OMS(M5),避免重复。
4. 供应商配送采购单 在 WMS 里也要走收货和审核才会加库存。"提交即生效"只是 VMS 自己的口径,与 OMS 实际库存会有差异,需要在对账时说明。

# inputs
1, categories and categories_translation table schema in oms
docs/reference folder
categories.sql
and categories_translation.sql

2, brand sample
brand sample.png

3, wms suppliers table
wms_suppliers.sql

# issues
 for any issue fix, update fileupload.sh

1,
2,
3, for image upload not in the specified size, provide a trim feature similar as the pictureTrim.png 
4, refer to issue4 file
5, after saving an item, the image is not visible when viewing

图片
封面图
分享海报图
产品主图
产品详情图
SKU 图

6, now image is saved local

封面图*
https://fileshare.ebest.com.au/vms/storage/images/1bf3568d-5355-476a-ab8c-6f3a18aac67e-Screenshot_2026-11-24_at_22.49.08.png

need to save into S3 in the same way as oms


configuration
in oms:
RAILS_MASTER_KEY=xx RAILS_ENV=production bin/rails credentials:show



# architecture

1, based on Laravel
2, contain eBest logo
3, similar look and feel as wms
4, all vms table start with vms_ to be easily differentiated

# plan - reference

建议:把 VMS 做成独立的 Laravel 应用,放在 OMS 和 WMS 之外。它通过一层很薄的集成适配层,只对接 OMS 和 WMS。分阶段上线,第 1 阶段不要求 OMS 和 WMS 先改动。

这个结论来自 docs/integration-points.md、onboardingSystem.md 和现有代码结构。我没有实际调用任何接口,下面的依据都是静态阅读代码得出的。

为什么不嵌入 OMS 或 WMS

- OMS 是 Rails,WMS 是 Laravel。 两边都是运营在用的核心系统。VMS 要面向外部供应商开放,把外部用户放进内部系统会扩大攻击面。
- OMS 目前只有管理员会话登录, 没有服务账号。WMS 里有硬编码凭证,OMS 的代码注释里有 AWS key ID。
- WMS 是 OMS 的调用方。 定时任务由 WMS 驱动(拉订单、推库存、同步采购单),OMS 自己从不主动调用 WMS。
- 团队已有 Laravel 经验。 fileshare 就是 Laravel,账号、角色、权限、报表、定时任务都可以复用。

推荐架构

供应商 ──> VMS 门户 (Laravel, 独立库、独立域名)
              │  适配层: 只有这里知道 OMS/WMS 的接口细节
              ├──> OMS  /wms/api/v1/* (现有) + 新增服务账号接口
              ├──> WMS  采购单、供应商接口
              └──> S3/CDN (图片,最小权限)

- VMS 自己保存的数据: 供应商、注册资料、商品草稿、采购单草稿、对账记录。
- 采购单号、审核、库存入账仍以 WMS 为准。 这与 3.5 节"不另建单据体系"的原则一致。
- VMS 只调用已有接口或新增的少量接口, 不直接读写 OMS 或 WMS 的数据库。
- 集成适配层单独成层, 这样接口就绪前后,上层业务代码不用改。

分阶段实施

┌──────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────┬──────────────────────────┐
│     阶段     │                                                  内容                                                  │    对 OMS/WMS 的依赖     │
├──────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┤
│ 1.           │ 供应商注册、商品录入、导出 import-items.xlsx、导出采购单批量导入                                       │ 无,可立即启动            │
│ 无集成可用   │ Excel、状态跟踪。运营手工导入后回填采购单号。                                                          │                          │
├──────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┤
│ 2. 只读集成  │ 库存与销量只读查询,以及按供应商的发货和缺货退货查询。这对应 goal 12 的第 1、3 项。                     │ OMS 新增只读接口,约 1–2  │
│              │                                                                                                        │ 周                       │
├──────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┤
│ 3. 写入集成  │ 服务账号、采购单创建接口、审核回调、库存绝对值设置、供应商建档。                                       │ OMS/WMS                  │
│              │                                                                                                        │ 都要改,是关键路径        │
├──────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────┤
│ 4.           │ 每周对账、结算数据汇总、图片直传 S3。                                                                  │ 取决于前面阶段           │
│ 对账与结算   │                                                                                                        │                          │
└──────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────────────────┘

第 1 阶段能很快产出价值,同时给 OMS/WMS 的改动留出排期时间。你们状态报告里的 5 个依赖项(源码、LAB/生产环境访问)还没解决,第 3 阶段会被这些依赖卡住。

动手前必须先定的事

1. 库存口径。 供应商自有仓的库存只记在 VMS 和 OMS 里。进了 eBest 仓的库存以 WMS 采购单审核为准。必须避免 batch_update_quantity_v3 把供应商自有仓库存重复加一遍(DEP-3)。
2. 服务账号认证。 现在的 MD5(shared_key + timestamp) 偏弱,建议改成每个服务账号一把可轮换的密钥,并改用 HMAC。
3. Runbow 与 Jerry 是不是同一个系统(Q17)。 这决定库存同步要不要多一条路径。
4. 图片上传。 建议用单独的最小权限 AWS 账号,而不是复用 OMS 的凭证(Q16)。