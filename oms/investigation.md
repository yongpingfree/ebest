
  Ran 2 shell commands

Rails app. Let me narrow to order-limit-specific code.

  Ran 3 shell commands

Now the enforcement point for the delivery-date capacity limits.

  Ran 3 shell commands

The OMS (a Rails app, oms/www/lvtuantuan/releases/20261112143032) applies order limits in two groups. One group limits what a buyer can order. The other limits how many orders or addresses can be delivered per day.

1. Buyer-side limits (checked when the order is created)

All are validations in app/models/magic_bean/order.rb (lines 309–321, run on: :create):

Limit: Item purchase quota
Where: check_buy_quota (order.rb:1789)
Rule: items.buy_quota is the maximum per buyer account, and 0 means unlimited. items.buy_quota_days sets the window in days, and 0 means
  lifetime. The check sums this user's quantity of that item over user.orders.effective in the window. It rejects the order if that sum plus the
   new quantity exceeds buy_quota. The error is error.order.purchase_limit.
────────────────────────────────────────
Limit: Unpaid order cap
Where: wait_buyer_pay_order_max_count (order.rb:1783)
Rule: The user can have at most MAX_WAIT_BUYER_PAY_COUNT = 5 orders in wait_buyer_pay status.
────────────────────────────────────────
Limit: New-user quota
Where: stock_keeping_unit.rb:323, new_user_buy_quota_invalid?
Rule: new_user_buy_quota applies when the SKU has a new-user price. It is also checked when adding to the cart (shopping_cart_item.rb:61,
  same_day_delivery_cart_items.rb).
────────────────────────────────────────
Limit: Concurrent submit lock
Where: beans_app/api/v1/orders.rb:196
Rule: A Redis key place_order_limit_at_the_same_time_<user_id> with a 10-second TTL rejects a second simultaneous order from the same user.
────────────────────────────────────────
Limit: Cross-border (AE) cap
Where: orders.rb:204
Rule: Orders under $1000 excluding GST only.

2. Daily delivery capacity limits (Redis counters)

These limits are on how many addresses or orders can be delivered per day. They work by hiding dates in the delivery-date picker rather than failing the order.

- Config (DB):
  - Store-wide: site_configs.merchant_delivery_orders_limit_every_day (address count per day) and merchant_delivery_total_orders_limit_every_day.
  - Per delivery-time area and period: delivery_times.limited_by_orders_limit_every_day, delivery_time_period_settings.order_address_limit_every_day, and the specific_* overrides.
  - Self-pickup: self_pick_ups.self_pick_orders_limit_every_day.
  - Extra capacity: extra_orders_limits, per store and per delivery date. It adds extra address and order counts and applies once begin_at has passed and the order amount reaches order_amount_in_cent. Its model is extra_orders_limit.rb, and active_limit_from_redis reads it from Redis.
- Counters: Order#counter_to_redis and release_counter_from_redis (order.rb:2573–2610) increment and decrement the Redis keys:
  - store-<id>-<date>, a hash of receiver address to order count.
  - delivery-time-<id>-<date>-list-period-<pid>
  - self-pick-<id>-<date>
  - The *_ADDRESSES_COUNT keys hold the distinct address totals. recalculate_*_orders_data rebuilds them.
  - SyncOneMonthOrdersToRedisJob rebuilds the counters and the store-<id>-orders-limit-every-day value.
- Enforcement: Item#calculate_earliest_delivery_time (item.rb:760–830) loops day by day from the earliest dispatch date. It skips a date when:
  - the weekday isn't allowed, or
  - the distinct address count has reached the limit (self-pickup compares order count to self_pick_orders_limit_every_day).

  A limit of 0 means unlimited. Same-day delivery has its own equivalents in same_day_delivery_order.rb.
- Admin: the beans_admin API (extra_orders_limits.rb, site_configs.rb, self_pick_ups.rb) manages these settings. Permission is extra_orders_limits (ability.rb:240).

Things to note for the onboarding design

- Daily capacity limits are soft. Once a date fills up, only the picker changes, and check_delivery_time doesn't re-check capacity at create time. So a race between two buyers can slightly exceed a limit.
- I didn't find a per-order quantity or amount cap, apart from the AE $1000 cap and buy_quota.
- The limits depend on Redis counters that are kept in step by increment and decrement callbacks. A drift is repaired only by the sync job.

If you want, I can look at how the delivery_time_period_settings and merchant_delivery_total_orders_limit_every_day fields are enforced. I didn't find where the total-orders limit is checked, and it may only be used in the admin or analysis views.

✻ Brewed for 34s · done Friday 11:59 pm

※ recap: Overall goal is the eBest fileshare and onboarding work; right now I was answering how the OMS applies order limits, and I've explained buyer-side quotas and Redis-based daily delivery capacity limits. Next action is yours: say whether to dig into where the total-orders limit is enforced. (disable recaps in /config)

❯ from GUI menu, what's the entry point for order limit setup?

  Ran 3 shell commands

I can't give you the exact menu path. The admin GUI front end isn't in this repo. The repo only holds the Rails backend and its beans_admin API, so the menu tree isn't here. What the code does show is the name of each setting and which permission controls it.

┌───────────────────────────────┬─────────────────────────────────────────────────────────────────┬───────────────────────────────────────┐
│             Limit             │                    Setting name in the admin                    │    Permission key (admin_user.rb)     │
├───────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┤
│ Extra daily capacity for a    │ 額外配送上限 (extra_orders_limit), with fields 额外配送单量 and │ extra_orders_limits                   │
│ store and delivery date       │  额外地址数配送上限                                             │                                       │
├───────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┤
│ Store-wide daily address      │ 每日地址数配送上限, the                                         │ Site config, which I didn't check     │
│ limit for merchant delivery   │ merchant_delivery_orders_limit_every_day field                  │                                       │
├───────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┤
│ Daily address limit per       │ 订单地址数上限 (order_address_limit_every_day), plus the toggle │ Delivery time management,             │
│ delivery area and period      │  受限于自派订单每日派送量上限                                   │ 配送时间管理 (delivery_times API)     │
├───────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┤
│ Self-pickup daily limit       │ 自提点每日自提限额 (self_pick_orders_limit_every_day)           │ Self-pickup point settings            │
│                               │                                                                 │ (self_pick_ups API)                   │
├───────────────────────────────┼─────────────────────────────────────────────────────────────────┼───────────────────────────────────────┤
│ Per-item purchase limit       │ 限购周期 (buy_quota_days) and the quota field buy_quota         │ Item/SKU edit page                    │
└───────────────────────────────┴─────────────────────────────────────────────────────────────────┴───────────────────────────────────────┘

The model locale files confirm the setting names only. They don't contain menu labels.

To find the menu entry in the live admin:
- Look for a menu named 額外配送上限 or similar. It only shows for admins who have the extra_orders_limits permission.
- Open the delivery-time (配送时间) and self-pickup point (自提点) edit pages for the per-area and self-pickup limits.
- Open the Site Config (全站配置) page for the store-wide address limit.
- Open an item's edit page for the 限购 fields.

If the admin front-end repo is available, point me to it and I can give you the exact menu path.

✻ Cooked for 13s · done 12:09 am

※ recap: You asked how the OMS applies order limits and where they're set in the admin GUI. I explained the buyer-side and daily-capacity limits, but the admin front-end isn't in the repo, so the exact menu path is unconfirmed. Next: share the admin front-end repo, or check the live admin. (disable recaps in /config)

❯ please check the screenshot form the menu and point out the entry

  Read 4 files, listed 1 directory, ran 3 shell commands

I checked every screenshot in the project and none show the OMS menu where order limits are set.

- screenshots.pptx has the fileshare app only: login, admin landing page, PDF settings, user management, upload and download pages.
- PO录入流程&审核.docx has screenshots of the PO or WMS system. Its menu has PDA PO 审核, 异常PO列表, PO状态查询, 供应商管理, 创建PO单, PO, PO集合, PO支付单, 产品, Account, 调拨出库单 and 用户. None of these is an order-limit entry, so I won't guess one from it.
- onboarding/onboard_images.jpg is an item-edit form with image uploads (封面, 产品主图 and so on). It has no limit fields.

I'm not going to pick an entry from these. Could you send a screenshot of the OMS admin sidebar (the Rails beans_admin front end), or add it to screenshots.pptx? Then I can point to the entry.

In the meantime, these are the labels to look for in that sidebar, taken from the code:
- 額外配送上限, the extra daily capacity per store and date.
- 配送时间 (delivery time management), which holds 订单地址数上限 per period.
- 自提点 (self-pickup point), which holds 自提点每日自提限额.
- 全站配置 (site config), which holds 每日地址数配送上限.
- Item edit, which holds 限购周期 and the purchase quota.

✻ Worked for 18s · done 12:16 am

❯ check screenshots folder

  Read 3 files, listed 1 directory

These screenshots show the 系统配置 and 配送管理 menus. Between them they cover three of the five limit settings. I can't see the 額外配送上限 entry or the item edit page, so I can't point to those.

┌──────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────┐
│                          Limit                           │                        Menu entry in your screenshots                         │
├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ Store-wide daily address limit (每日地址数配送上限)      │ 系统配置 → 全站配置 (screenshot 1, first item)                                │
├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ Per-area and per-period address limit (订单地址数上限,   │ 配送管理 → 配送时间管理 (screenshot 3)                                        │
│ plus the 受限于…每日派送量上限 toggle)                   │                                                                               │
├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ Self-pickup daily limit (自提点每日自提限额)             │ 配送管理 → 自提点 (screenshot 3)                                              │
├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ Extra daily capacity (額外配送上限)                      │ Not visible. It isn't under 系统配置 or 配送管理. It is probably in another   │
│                                                          │ top-level menu, for example 订单 or 营销, that you haven't captured.          │
├──────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────┤
│ Per-item purchase limit (限购 / buy_quota)               │ Not visible. It is on the item edit page, under the product menu.             │
└──────────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────┘

The first two are the main order limits.
- For the store-wide cap, open 全站配置 and look for the field 每日地址数配送上限.
- For limits by delivery area and time, open 配送时间管理, choose a delivery time record, and edit the 订单地址数上限 on each period row.

Screenshot 2 is the lower part of the 系统配置 list and has no limit-related entry.

If you scroll the sidebar and capture the other top-level menus, I can find the 額外配送上限 entry.

✻ Churned for 7s · done 12:17 am

※ recap: You asked where order limits are configured in the OMS admin, and I matched your screenshots to 全站配置, 配送时间管理 and 自提点. Next, please screenshot the other top-level menus so I can find the 額外配送上限 entry. (disable recaps in /config)

❯ is app/api/v1 in the oms source code?

  Ran 2 shell commands

Yes, /app/api/v1 is in the OMS source. It is the customer-facing app API, served by the Rails app in oms/www/lvtuantuan/releases/20261112143032.

- Mount point: config/routes.rb:97-100 mounts BeansApp::API under namespace :app, which gives the /app prefix.
- API class: app/services/beans_app/api.rb mounts API::V1 and API::V2, so v1 lives at /app/api/v1/....
- Endpoints: 66 files in app/services/beans_app/api/v1/, including orders.rb, items.rb, sessions.rb, members.rb, coupons.rb, addresses.rb and same_day_delivery_cart_items.rb.
- Docs: Swagger is served at /app/api/doc, but only outside production (routes.rb:99).

The OMS also has two sibling APIs:
- /mgt is the admin API, BeansAdmin::API in app/services/beans_admin/.
- /wms is Wms::API in app/services/wms/.

The app/api/v1 item in your CLAUDE.md dependency list names https://minimall.donkibuy.com/app/api/v1. I haven't checked that this checkout is the code behind that host. It may be the same codebase, since the path matches, but I can't confirm that from the code alone. This checkout is release 20261112143032, so it may not be the version running in production.

I can look at auth in ApiHelpers::AuthenticationHelper for the IT security review, or list the endpoints that don't require login.

✻ Crunched for 8s · done 12:31 am

❯ is there any header checking in the api?

  Ran 3 shell commands

Yes, but none of it is a gate. The API doesn't check User-Agent or X-Requested-With anywhere. A search of app/services, app/controllers, lib and config/initializers found nothing. There is also no Rack middleware (such as rack-attack) or before filter that screens clients.

The headers it does read are in app/services/api_helpers/ and beans_admin/helpers/:

┌───────────────────────────────────┬──────────────────────────────────────────────────────────────────┬──────────────────────────────────┐
│              Header               │                             Purpose                              │              Gate?               │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│                                   │ JWT, decoded by payload (authentication_helper.rb:169).          │                                  │
│ Authorization                     │ current_user is built from it, and endpoints that need login     │ Yes, but only per endpoint       │
│                                   │ call unauthenticated!.                                           │                                  │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│                                   │ Compared to a secret in Rails credentials. Used by               │ Yes, but only the WeChat         │
│ Api-Authorization-Token           │ check_api_authorization_token! and                               │ endpoints use it                 │
│                                   │ check_aus_api_authorization_token! (lines 87-93).                │ (v1/wechats.rb:8,                │
│                                   │                                                                  │ v2/wechats.rb:8)                 │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│ Current-Store-Id                  │ Picks the store. Defaults to the default store if absent.        │ No, it's a client-supplied value │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│ Current-Postal-Code,              │                                                                  │                                  │
│ Current-Suburb,                   │ Delivery area context.                                           │ No                               │
│ Current-Delivery-Area-Id          │                                                                  │                                  │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│ Current-App-Version               │ Read at line 60, but I found no version enforcement.             │ No                               │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│                                   │ app, mini_program or web, and any other value becomes            │                                  │
│ Ebest-Channel                     │ mini_program (base_helper.rb:65). It sets the order channel, so  │ No                               │
│                                   │ a client can pick its own channel.                               │                                  │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│ Locale                            │ Language.                                                        │ No                               │
├───────────────────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────┤
│ Store-Id                          │ Used in the admin API (/mgt).                                    │ No                               │
└───────────────────────────────────┴──────────────────────────────────────────────────────────────────┴──────────────────────────────────┘

Admin (/mgt) auth is session-cookie based (beans_admin/helpers/session_helper.rb) and doesn't use headers.

For the IT security review:
- No client fingerprinting. Any HTTP client can call /app/api/v1. Your sample API rule (reject unless User-Agent starts with okhttp or X-Requested-With is com.donkibuy.ebest) has no counterpart here.
- Client-controlled values. Ebest-Channel and Current-Store-Id both come from the client. This matters because Ebest-Channel is used when orders are created, and some logic depends on whether the order channel is app or mini_program, such as the Kuaima delivery check in order.rb.
- AWS key in the source. app/services/beans_admin/api/v1/aws_oss.rb:11 contains a pre-signed S3 URL in a doc example. It includes an access key ID (AKIA2UC27W5SFDCSIQQD) and a signature. It expired in 2024 (X-Amz-Expires=600), but check that the key itself has been rotated.

I can list which /app/api/v1 endpoints don't call any auth check, since those would be the ones fully open to any client.

✻ Churned for 14s · done 12:33 am