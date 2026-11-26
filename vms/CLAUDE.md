# goal

1, implement a framework with the following feature:
- entry point is /vms
- support new vendor self registration, with email confirmation code
- support new item onboarding, including all required fields (mandatory or optional), and images uploading
- support export to import-items.xlsx
- support new PO document
- support export of new PO document
- support status viewing of new item and PO

2, to be updated

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