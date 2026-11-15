# 全站内容多语系配置对照表

需要说明多语系配置的内容添加在这里。

模板：

- `key`: 代码里需要通过该 key 获取值
- `name`: 展示给管理员的中文说明
- `kind`: app 或 admin，app 表示该信息会返回给 app 使用，admin 表示只在后台使用
- `store_id`: 门店ID，为空则表示全门店共用
- `value_zh_cn`: 简体中文值
- `value_zh_tw`: 繁体中文值
- `value_en`: 英文值

以买家留言提示文字举例：

- `key`: `order_buyer_message_placeholder`
- `name`: 下单页买家留言提示文字
- `kind`: app
- `value_zh_cn`: 这里不要备注派送时间哦，如有特殊配送需求，请先联系客服确认哦~
- `value_zh_tw`: 這裡不要備註派送時間哦，如有特殊配送需求，請先聯繫客服確認哦~
- `value_en`: Do not comment delivery time here. If you have special delivery needs, please contact customer service first

执行代码：

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_buyer_message_placeholder", kind: :app)
config.name = "下单页买家留言提示文字"
config.value_zh_cn = "这里不要备注派送时间哦，如有特殊配送需求，请先联系客服确认哦~"
config.value_zh_tw = "這裡不要備註派送時間哦，如有特殊配送需求，請先聯繫客服確認哦~"
config.value_en = "Do not comment delivery time here. If you have special delivery needs, please contact customer service first"
config.save
```

## App key values

### 买家留言提示文字

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_buyer_message_placeholder", kind: :app)
config.name = "下单页买家留言提示文字"
config.value_zh_cn = "这里不要备注派送时间哦，如有特殊配送需求，请先联系客服确认哦~"
config.value_zh_tw = "這裡不要備註派送時間哦，如有特殊配送需求，請先聯繫客服確認哦~"
config.value_en = "Do not comment delivery time here. If you have special delivery needs, please contact customer service first"
config.save
```


### 跨境购买家留言提示文字

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "ae_order_buyer_message_placeholder", kind: :app)
config.name = "跨境购下单页买家留言提示文字"
config.value_zh_cn = "请使用英文留言。"
config.value_zh_tw = "請使用英文留言。"
config.value_en = "Please use English to leave a message."
config.save
```

### 跨境购下单页弹窗提示文字

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "place_ae_order_notice", kind: :app)
config.name = "跨境购下单页弹窗"
config.value_zh_cn = "您选购的商品为跨境商品，非质量问题不支持退换货。系统提供的送达时间为预估时间，实际送达时间可能会有所不同，请以最终配送为准。"
config.value_zh_tw = "您選購的商品為跨境商品，非質量問題不支持退換貨。系統提供的到達時間為預估時間，實際到達時間可能會有所不同，請以最終配送為準。"
config.value_en = "The goods you purchased are cross-border goods. Non-quality issues do not support returns and exchanges. The delivery time provided by the system is an estimated time. The actual delivery time may be different. Please refer to the final delivery."
config.save
```

### 下单页须知提示文字

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "place_order_should_know", kind: :app)
config.name = "下单页须知提示文字"
config.value_zh_cn = "您在下单时可以选择配送日期，但暂不支持指定具体配送时间，请根据您的情况选择合适的日期。收货后，请妥善存放生鲜及冷冻产品，并尽快放入冰箱，避免融化或变温。我们仅受理收货后24小时内的售后问题，敬请谅解。"
config.value_zh_tw = "您在下单時可以選擇配送日期，但暫不支持指定具體配送時間，請根據您的情況選擇合適的日期。收貨後，請妥善存放鮮生及冷凍產品，並盡快放入冰箱，避免融化或變溫。我們僅受理收貨後24小時內的售後問題，敬請諒解。"
config.value_en = "You can choose a delivery date when placing an order, but it does not currently support specifying a specific delivery time. Please choose an appropriate date based on your situation. After receiving the goods, please store the fresh and frozen products properly and put them in the refrigerator as soon as possible to avoid melting or temperature changes. We only accept after-sales issues within 24 hours after delivery, please understand."
config.save
```

### 确认订单信息顶部提示语
```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "place_order_merchant_delivery_top_tips", kind: :app)
config.name = "确认订单信息顶部提示语(自派)"
config.value_zh_cn = "请在配送时间段内，注意接听司机电话，3次不接听，将自动转为“自提”。详情请进入“我的”页面，联系客服。"
config.value_zh_tw = "請在配送時間段內，注意接聽司機電話，3次不接聽，將自動轉為“自提”。詳情請進入“我的”頁面，聯繫客服。"
config.value_en = "Please pay attention to answering the driver's phone during the delivery time. If you don't answer the phone for 3 times, it will automatically change to \"self-pickup\". For details, please go to the \"Account\" page and contact customer service."
config.save
```

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "place_order_self_pick_top_tips", kind: :app)
config.name = "确认订单信息顶部提示语(自提)"
config.value_zh_cn = ""
config.value_zh_tw = ""
config.value_en = ""
config.save
```

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "place_order_express_top_tips", kind: :app)
config.name = "确认订单信息顶部提示语(邮寄)"
config.value_zh_cn = "邮寄单号，将在订单完成打包后显示，请留意短信和订单内邮寄单号更新，查询邮寄单号，请访问 https://auspost.com.au/mypost/track/#/search"
config.value_zh_tw = "郵寄單號，將在訂單完成打包後顯示，請留意短信和訂單內郵寄單號更新，查詢郵寄單號，請訪問 https://auspost.com.au/mypost/track/#/search"
config.value_en = "The mailing order number will be displayed after the order is packaged. Please pay attention to the update of the mailing order number in the text message and the order. To check the mailing order number, please visit https://auspost.com.au/mypost/track/#/search"
config.save
```

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "place_ae_order_top_tips", kind: :app)
config.name = "确认订单信息顶部提示语(跨境购邮寄)"
config.value_zh_cn = "邮寄单号，将在订单完成打包后显示，请留意短信和订单内邮寄单号更新，查询邮寄单号，请访问 https://auspost.com.au/mypost/track/#/search"
config.value_zh_tw = "郵寄單號，將在訂單完成打包後顯示，請留意短信和訂單內郵寄單號更新，查詢郵寄單號，請訪問 https://auspost.com.au/mypost/track/#/search"
config.value_en = "The mailing order number will be displayed after the order is packaged. Please pay attention to the update of the mailing order number in the text message and the order. To check the mailing order number, please visit https://auspost.com.au/mypost/track/#/search"
config.save
```

### 支付方式提示文案

```ruby
{
  "payment_wechat_note" => "小程序微信支付Note",
  "payment_omipay_wechat_note" => "Omipay微信支付Note",
  "payment_omipay_alipay_note" => "Omipay支付宝支付Note",
  "payment_supay_wechat_note" => "Supay微信支付Note",
  "payment_supay_alipay_note" => "Supay支付宝支付Note",
  "payment_commweb_note" => "VISA/MASTER信用卡支付Note",
  "payment_unionpay_note" => "银联支付Note",
  "payment_apple_pay_note" => "银联ApplePay Note",
  "payment_cba_apple_pay_note" => "CBA ApplePay Note",
  "payment_cba_google_pay_note" => "CBA GooglePay Note",
  "payment_stripe_credit_card_note" => "Stripe信用卡支付",
  "payment_stripe_apple_pay_note" => "Stripe ApplePay支付",
  "payment_stripe_google_pay_note" => "Stripe GooglePay支付",
}.each_pair do |key, name|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: key, kind: :app)
  config.name = name
  config.save
end
```

### 购物车顶部提示

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "shopping_cart_page_top_tips", kind: :app, store_id: store.id)
  config.name = "购物车顶部提示"
  # 每个门店都有不同的购物车顶部提示，先不预设默认值
  config.save
end
```

### 跨境购购物车顶部提示

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "ae_shopping_cart_page_top_tips", kind: :app, store_id: store.id)
  config.name = "跨境购购物车顶部提示"
  # 每个门店都有不同的购物车顶部提示，先不预设默认值
  config.save
end
```

### 取消订单退款理由

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "direct_refund_reasons", kind: :app)
config.name = "取消订单退款理由"
config.hint = "多个理由使用分号隔开"
config.value_zh_cn = "质量有问题; 想重新下订单; 货物数量与订单不符; 与客服协商退款"
config.value_zh_tw = "質量有問題; 想重新下訂單; 貨物數量與訂單不符; 與客服協商退款"
config.value_en = "There is a problem with quality; Want to re-order; The number of goods does not match the order; Negotiate refund with customer service"
config.save
```

### 申请售后理由

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "after_sale_reasons", kind: :app)
config.name = "申请售后理由"
config.hint = "多个理由使用分号隔开"
config.value_zh_cn = "质量有问题; 想重新下订单; 货物数量与订单不符; 与客服协商退款"
config.value_zh_tw = "質量有問題; 想重新下訂單; 貨物數量與訂單不符; 與客服協商退款"
config.value_en = "There is a problem with quality; Want to re-order; The number of goods does not match the order; Negotiate refund with customer service"
config.save
```

### 配送方式备注配置

```ruby
MagicBean::Store.find_each do |store|
  {
    "checkout_merchant_delivery_remark" => "送货上门备注",
    "checkout_self_pick_remark" => "自提备注",
    "checkout_express_remark" => "邮寄备注",
  }.each_pair do |key, name|
    config = MagicBean::MultiLangConfig.find_or_initialize_by(key: key, kind: :app, store_id: store.id)
    config.name = name
    config.save
  end
end
```

### 搜索栏提示文字

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "header_search_bar_placeholder", kind: :app, store_id: store.id)
  config.name = "页面顶部搜索栏提示文字"
  config.hint = "最大长度为90个字符（建议不超过 30 个汉字）"
  config.save
end
```

## 管理后台 key values

### 暂停用户下单提示语

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_creation_api_disabled_tips", kind: :admin, store_id: store.id)
  config.name = "暂停用户下单提示语"
  config.save
end
```

### 普通订单支付后短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_paid_message", kind: :admin)
config.name = "普通订单支付后短信通知"
config.hint = "一条短信 67 个字符, 超出算两条。订单号使用: {{no}}，配送方式用: {{delivery_type}}，实际支付金额使用{{payment_total}}"
config.value_zh_cn = "【eBest】已经成功支付{{payment_total}}(实际支付金额)，请留意{{merchant_delivery_date}}{{delivery_type}}的短信通知，如有疑问，请登录APP『我的』页面，联系客服。订单打包完成之后，您会收到一个短信，点击短信中的link可以追踪司机到达的时间。祝您购物愉快！"
config.value_zh_tw = "【eBest】已經成功支付{{payment_total}}(實際支付金額)，請留意{{merchant_delivery_date}}{{delivery_type}}的短信通知，如有疑問，請登錄APP『我的』頁面，聯繫客服。訂單打包完成之後，您會收到一個短信，點擊短信中的link可以追踪司機到達的時間。祝您購物愉快！"
config.value_en = "【eBest】You have successfully paid {{payment_total}} (actual payment amount), please pay attention to {{merchant_delivery_date}} {{delivery_type}}. If you have any questions, log in to the App \"My\" page and contact customer service. After the order is packed, you will receive a SMS, click LINK in the SMS to track the time of the driver's arrival. Happy shopping!"
config.save
```

### 普通订单支付后App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_paid_notification", kind: :admin)
config.name = "普通订单支付后App推送通知"
config.hint = "订单号使用: {{no}}，配送方式用: {{delivery_type}}，实际支付金额使用{{payment_total}}"
config.value_zh_cn = "【eBest】您尾号为{{no}} 的订单已经成功支付，请留意{{merchant_delivery_date}}的通知，如有疑问请联系App客服。"
config.value_zh_tw = "【eBest】您尾號為{{no}} 的訂單已經成功支付，請留意{{merchant_delivery_date}}的通知，如有疑問請聯繫App客服。"
config.value_en = "【eBest】The order of your tail number {no}} has been successfully paid. Please pay attention to the notification of {{merchant_delivery_date}}. If you have any questions, please contact the App customer service."
config.save
```

### 自提订单发货短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "self_pick_order_dispatched_message", kind: :admin)
config.name = "自提订单发货短信通知"
config.hint = "订单号使用: {{no}}，营业时间使用: {{opening_hours}}，自提码使用: {{self_pick_up_code}}，自提点地址使用: {{full_address}}，自提点地址包含电话号码， 配送日期使用: {{delivery_date}}, 配送时间使用: {{prefer_time}}"
config.value_zh_cn = "【eBest】您的订单已经完成分拣打包，您的自提码为【{{self_pick_up_code}}】, 自提点地址为{{full_address}},自提点营业时间为：{{opening_hours}}, 您今天就可以来自提啦！"
config.value_zh_tw = "【eBest】您的訂單已經完成分揀打包，您的自提碼為【{{self_pick_up_code}}】, 自提點地址為{{full_address}},自提點營業時間為：{{opening_hours}}, 您今天就可以來自提啦！"
config.value_en = "【eBest】Your order has been sorted and packed. Your self -order is [{{self_pick_up_code}}], and the self -lifting address is {{full_address}}. You can come from mention today!"
config.save
```

### 自提订单发货App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "self_pick_order_dispatched_notification", kind: :admin)
config.name = "自提订单发货App推送通知"
config.hint = "订单号使用: {{no}}，营业时间使用: {{opening_hours}}，自提码使用: {{self_pick_up_code}}，自提点地址使用: {{full_address}}，自提点地址包含电话号码， 配送日期使用: {{delivery_date}}, 配送时间使用: {{prefer_time}}"
config.value_zh_cn = "【eBest】您尾号为{{no}}的订单已经完成分拣打包，您的自提码为【{{self_pick_up_code}}】, 自提点地址为{{full_address}},自提点营业时间为：{{opening_hours}}, 您今天就可以来自提啦！"
config.value_zh_tw = "【eBest】您尾號為{{no}}的訂單已經完成分揀打包，您的自提碼為【{{self_pick_up_code}}】, 自提點地址為{{full_address}},自提點營業時間為：{{opening_hours}}, 您今天就可以來自提啦！"
config.value_en = "【eBest】The order of your tail number {{no}} has been sorted and packaged. Your code is [{{self_pick_up_code}}], and the self-lifting address is {{full_address}}. {{opening_hours}}, you can come from mention today!"
config.save
```

## 自派订单发货短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "merchant_delivery_order_dispatched_message", kind: :admin)
config.name = "自派订单发货短信通知"
config.hint = "订单号使用: {{no}}，配送日期使用: {{delivery_date}}, 配送时间使用: {{prefer_time}}, 物流追踪使用: {{delivery_track}}"
config.value_zh_cn = "【eBest】您尾号为{{no}}的订单，已经分拣打包完毕开始装车，预计1-2小时发车，查询订单到达时间，请点击链接 {{delivery_track}} ，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】您尾號為{{no}}的訂單，已經分揀打包完畢開始裝車，預計1-2小時發車，查詢訂單到達時間，請點擊鏈接 {{delivery_track}} ，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Orders with {{no}}, you have already sorted and packed and start loading. It is expected to depart for 1-2 hours. Query the order arrival time, please click the link {delivery_track}}. If you have any questions, please consult the customer service."
config.save
```

### 自派订单发货App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "merchant_delivery_order_dispatched_notification", kind: :admin)
config.name = "自派订单发货App推送通知"
config.hint = "订单号使用: {{no}}，配送日期使用: {{delivery_date}}, 配送时间使用: {{prefer_time}}, 物流追踪使用: {{delivery_track}}"
config.value_zh_cn = "【eBest】您尾号为{{no}}的订单，已经分拣打包完毕开始装车，预计1-2小时发车，查询订单到达时间，请点击链接 {{delivery_track}} ，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】您尾號為{{no}}的訂單，已經分揀打包完畢開始裝車，預計1-2小時發車，查詢訂單到達時間，請點擊鏈接 {{delivery_track}} ，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Orders with {{no}}, you have already sorted and packed and start loading. It is expected to depart for 1-2 hours. Query the order arrival time, please click the link {{delivery_track}}. If you have any questions, please consult the customer service."
config.save
```

### 邮寄订单发货短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "express_order_dispatched_message", kind: :admin)
config.name = "邮寄订单发货短信通知"
config.hint = "订单号使用: {{no}}，邮寄单号使用: {{logistic_no}}"
config.value_zh_cn = "【eBest】您的订单{{no}}，已经分拣打包完成，快递单号为 {{logistic_no}}，查询快递状态请登录 https://auspost.com.au/mypost/track/#/search 。如有疑问请登录eBest小程序或者APP，进入\"我的\"页面咨询客服"
config.value_zh_tw = "【eBest】您的訂單{{no}}，已經分揀打包完成，快遞單號為 {{logistic_no}}，查詢快遞狀態請登錄 https://auspost.com.au/mypost/track/#/search 。如有疑問請登錄eBest小程序或者APP，進入\"我的\"頁面諮詢客服"
config.value_en = "【eBest】Your order {{no}} has been sorted and packaged. The courier number is {{logistic_no}}, please log in to https://auspost.com.au/mypost/track/search. If you have any questions, please log in to the Ebest applet or app to enter the \"My\" page consulting customer service"
config.save
```

### 邮寄订单发货App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "express_order_dispatched_notification", kind: :admin)
config.name = "邮寄订单发货App推送通知"
config.hint = "订单号使用: {{no}}，邮寄单号使用: {{logistic_no}}"
config.save
```

### 派送时间更新短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "merchant_delivery_time_updated_message", kind: :admin)
config.name = "派送时间更新短信通知"
config.hint = "订单号使用: {{no}}，邮寄单号使用: {{logistic_no}}"
config.save
```

### 派送时间更新App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "merchant_delivery_time_updated_notification", kind: :admin)
config.name = "派送时间更新App推送通知"
config.hint = "订单号使用: {{no}}，邮寄单号使用: {{logistic_no}}"
config.save
```

### 订单整单缺货短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_stockout_message", kind: :admin)
config.name = "订单整单缺货短信通知"
config.hint = "订单号使用: {{no}}, 配送方式用: {{delivery_type}}"
config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，由于本订单所有商品均缺货，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，由於本訂單所有商品均缺貨，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Dear guest, your order {{no}}, because all the products of this order are out of stock, the system has applied for your refund automatically, and the refund will be returned to your payment account within 3 working days. Sorry for the troubles. If you have any questions, please consult customer service."
config.save
```

### 订单整单缺货App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_stockout_notification", kind: :admin)
config.name = "订单整单缺货App推送通知"
config.hint = "订单号使用: {{no}}, 配送方式用: {{delivery_type}}"
config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，由于本订单所有商品均缺货，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，由於本訂單所有商品均缺貨，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Dear guest, your order {{no}}, because all the products of this order are out of stock, the system has applied for your refund automatically, and the refund will be returned to your payment account within 3 working days. Sorry for the troubles. If you have any questions, please consult customer service."
config.save
```

### 订单部分缺货短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_partly_stockout_message", kind: :admin)
config.name = "订单部分缺货短信通知"
config.hint = "订单号使用: {{no}}, 配送方式用: {{delivery_type}}, 缺货清单用: {{stockout_items}}。 缺货清单例子: 小紫薯1kg - 1公斤 x 1;草莓 250g - 1盒 x 1"
config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，{{stockout_items}}等产品今天缺货啦，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，{{stockout_items}}等產品今天缺貨啦，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Dear guest, your order {{no}}, {{stockout_items}} and other products are out of stock today. Account. Sorry for the troubles. If you have any questions, please consult customer service."
config.save
```

### 订单部分缺货App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_partly_stockout_notification", kind: :admin)
config.name = "订单部分缺货App推送通知"
config.hint = "订单号使用: {{no}}, 配送方式用: {{delivery_type}}, 缺货清单用: {{stockout_items}}。 缺货清单例子: 小紫薯1kg - 1公斤 x 1;草莓 250g - 1盒 x 1"
config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，{{stockout_items}}等产品今天缺货啦，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，{{stockout_items}}等產品今天缺貨啦，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Dear guest, your order {{no}}, {{stockout_items}} and other products are out of stock today. Account. Sorry for the troubles. If you have any questions, please consult customer service."
config.save
```

### 管理后台发起售后短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "admin_create_after_sale_message", kind: :admin)
config.name = "管理后台发起售后短信通知"
config.hint = "订单号使用: {{no}}, 售后清单用: {{after_sales_items}}。 售后清单例子: 小紫薯1kg - 1公斤 x 1;草莓 250g - 1盒 x 1"
config.value_zh_cn = "【eBest】您好，您的订单{{no}}，{{after_sales_items}}由于缺货/售后原因，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】您好，您的訂單{{no}}，{{after_sales_items}}由於缺貨/售後原因，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Hello, your order {{no}}, {{after_sales_items}} due to the shortage/after-sales reasons, the system has applied for a refund automatically, and the refund will be returned to your payment account within 3 working days. Sorry for the troubles. If you have any questions, please consult customer service."
config.save
```

### 管理后台发起售后App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "admin_create_after_sale_notification", kind: :admin)
config.name = "管理后台发起售后App推送通知"
config.hint = "订单号使用: {{no}}, 售后清单用: {{after_sales_items}}。 售后清单例子: 小紫薯1kg - 1公斤 x 1;草莓 250g - 1盒 x 1"
config.value_zh_cn = "【eBest】您好，您的订单{{no}}，{{after_sales_items}}由于缺货/售后原因，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
config.value_zh_tw = "【eBest】您好，您的訂單{{no}}，{{after_sales_items}}由於缺貨/售後原因，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
config.value_en = "【eBest】Hello, your order {{no}}, {{after_sales_items}} due to the shortage/after-sales reasons, the system has applied for a refund automatically, and the refund will be returned to your payment account within 3 working days. Sorry for the troubles. If you have any questions, please consult customer service."
config.save
```

### 管理后台发起积分售后通知模板

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "admin_create_after_sale_integral_notification", kind: :admin)
config.name = "管理后台发起积分售后通知模板"
config.hint = "订单号使用: {{no}}, 售后清单用: {{after_sales_items}}。 售后清单例子: 小紫薯1kg - 1公斤 x 1;草莓 250g - 1盒 x 1"
config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，{{after_sales_items}} 等，由于缺货/售后问题，已经为您自动申请退款，退款会在3个工作日内以积分形式退到您的账户。非常抱歉给您带来的麻烦，如有疑问，请您登录eBest小程序或者APP，进入\"我的\"查看“售后订单”。"
config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，{{after_sales_items}} 等，由於缺貨/售後問題，已經為您自動申請退款，退款會在3個工作日內以積分形式退到您的賬戶。非常抱歉給您帶來的麻煩，如有疑問，請您登錄eBest小程序或者APP，進入“我的”查看“售後訂單”。"
config.value_en = "【eBest】Dear guest, your order {{no}}, {{after_sales_items}}, etc., due to the shortage of stock/after-sales, the refund will be automatically applied for the refund. Go to your account. Sorry for the troubles. If you have any questions, please log in to the EBEST applet or APP to enter the \"My\" View after-sales order."
config.save
```

### 管理后台发起优惠券售后通知模板

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "admin_create_after_sale_coupon_notification", kind: :admin)
config.name = "管理后台发起优惠券售后通知模板"
config.hint = "订单号使用: {{no}}, 售后清单用: {{after_sales_items}}。 售后清单例子: 小紫薯1kg - 1公斤 x 1;草莓 250g - 1盒 x 1"
config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，{{after_sales_items}} 等，由于缺货/售后问题，已经为您自动申请退款，退款会在3个工作日内以优惠券形式退到您的账户。非常抱歉给您带来的麻烦，如有疑问，请您登录eBest小程序或者APP，进入“我的”查看“售后订单”。"
config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，{{after_sales_items}} 等，由於缺貨/售後問題，已經為您自動申請退款，退款會在3個工作日內以優惠券形式退到您的賬戶。非常抱歉給您帶來的麻煩，如有疑問，請您登錄eBest小程序或者APP，進入“我的”查看“售後訂單”。"
config.value_en = "【eBest】Dear guest, your order {{no}}, {{after_sales_items}}, etc., due to the shortage of stock/after-sales problems, the refund will be automatically applied for a refund. Form to your account. Sorry for the troubles. If you have any questions, please log in to the EBEST applet or APP to enter the \"My\" View after-sales order."
config.save
```

### 新人推荐信

```ruby
MagicBean::Store.find_each do |store|
  # 消息内容
  content = MagicBean::MultiLangConfig.find_or_initialize_by(key: "new_user_letter_message_text", kind: :admin, store_id: store.id)
  content.name = "新人推荐信推送内容"
  content.value_zh_cn = ""
  content.value_zh_tw = ""
  content.value_en = ""
  content.hint = "需同时配置“新人推荐信跳转页面编号”才会发送新人推荐信"
  content.save

  # 跳转页面
  page_id = MagicBean::MultiLangConfig.find_or_initialize_by(key: "new_user_letter_custom_page_id", kind: :admin, store_id: store.id)
  page_id.name = "新人推荐信跳转页面编号"
  page_id.value_zh_cn = ""
  page_id.value_zh_tw = ""
  page_id.value_en = ""
  page_id.hint = "请直接填写自定义页面对应的编号（第一列的数字），并确保自定义页面编号与门店ID匹配。需同时配置“新人推荐信推送内容”才会发送新人推荐信"
  page_id.save
end
```

### 直播置顶订单支付后短信通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "live_top_order_paid_message", kind: :admin)
config.name = "直播置顶订单支付后短信通知"
config.hint = "一条短信 67 个字符, 超出算两条。订单号使用: {{no}}，配送日期用: {{merchant_delivery_date}}，实际支付金额使用{{payment_total}}"
config.value_zh_cn = "【eBest】已经成功支付{{payment_total}}(实际支付金额)，请留意{{merchant_delivery_date}}需要有其他待发货主单，才可以替您合并发货。祝您购物愉快！"
config.value_zh_tw = "【eBest】已經成功支付{{payment_total}}(實際支付金額)，請留意{{merchant_delivery_date}}需要有其他待發貨主單，才可以替您合併發貨。祝您購物愉快！"
config.value_en = "【eBest】You have successfully paid {{payment_total}} (actual payment amount), please pay attention to {{merchant_delivery_date}} . Happy shopping!"
config.save
```

### 直播置顶订单支付后App推送通知

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "live_top_order_paid_notification", kind: :admin)
config.name = "直播置顶订单支付后App推送通知"
config.hint = "订单号使用: {{no}}，配送日期用: {{merchant_delivery_date}}，实际支付金额使用{{payment_total}}"
config.value_zh_cn = "【eBest】您尾号为{{no}} 的订单已经成功支付，请留意{{merchant_delivery_date}}的通知，如有疑问请联系App客服。"
config.value_zh_tw = "【eBest】您尾號為{{no}} 的訂單已經成功支付，請留意{{merchant_delivery_date}}的通知，如有疑問請聯繫App客服。"
config.value_en = "【eBest】The order of your tail number {no}} has been successfully paid. Please pay attention to the notification of {{merchant_delivery_date}}. If you have any questions, please contact the App customer service."
config.save
```

### 直播置顶订单待确认短信通知（待修改）

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "live_top_order_confirm_message", kind: :admin)
config.name = "直播置顶订单待确认短信通知"
config.hint = "一条短信 67 个字符, 超出算两条。订单号使用: {{no}}，配送日期用: {{merchant_delivery_date}}"
config.value_zh_cn = "请留意，发货日期{{merchant_delivery_date}}，您尚未有其他的待发货主单，请抓紧在今晚截单前，下单并支付其他订单，以避免您的订单{{no}}被取消。祝您购物愉快！"
config.value_zh_tw = "請留意，發貨日期{{merchant_delivery_date}}，您尚未有其他的待發貨主單，請抓緊在今晚截單前，下單並支付其他訂單，以避免您的訂單{{no}}被取消。祝您購物愉快！"
config.value_en = ""
config.save
```

### 直播置顶订单待确认App推送通知（待修改）

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "live_top_order_confirm_notification", kind: :admin)
config.name = "直播置顶订单待确认App推送通知"
config.hint = "订单号使用: {{no}}，配送日期用: {{merchant_delivery_date}}"
config.value_zh_cn = "请留意，发货日期{{merchant_delivery_date}}，您尚未有其他的待发货主单，请抓紧在今晚截单前，下单并支付其他订单，以避免您的订单{{no}}被取消。祝您购物愉快！"
config.value_zh_tw = "請留意，發貨日期{{merchant_delivery_date}}，您尚未有其他的待發貨主單，請抓緊在今晚截單前，下單並支付其他訂單，以避免您的訂單{{no}}被取消。祝您購物愉快！"
config.value_en = ""
config.save
```

### 送货上楼提示语

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_deliver_to_door_text", kind: :admin, store_id: store.id)
  config.name = "送货上楼提示语"
  config.value_zh_cn = "如果您选择送货上楼： a. 请务必在家等待。 b. 并提供可用的停车位及送货指引。 c. 若没有合适的停车位，司机可能无法完成此服务。 d. 此服务属于司机本职之外，如果您对服务满意，可以用小小的打赏作为感谢。"
  config.value_zh_tw = "如果您選擇送貨上樓： a. 請務必在家等待。 b. 並提供可用的停車位及送貨指引。 c. 若沒有合適的停車位，司機可能無法完成此服務。 d. 此服務屬於司機本職之外，如果您對服務滿意，可以用小小的打賞作爲感謝。"
  config.value_en = "If you choose delivery to upstairs: a. Please make sure to be home and wait. b. Provide an available parking space and delivery instructions. c. If there's no suitable parking space, the driver may be unable to complete this service. d. This service is beyond the driver's duty, and if you're satisfied, a small tip would be appreciated as gratitude."
  config.save
end
```

### 确认订单页 放在门口选项名称

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_authority_to_leave_house_name", kind: :app, store_id: store.id)
  config.name = "放在门口选项名称（住宅）"
  config.value_zh_cn = "允许放置在门口"
  config.value_zh_tw = "允許放置在門口"
  config.value_en = "Allowed to be placed at door"
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_authority_to_leave_apartment_name", kind: :app, store_id: store.id)
  config.name = "放在门口选项名称（公寓）"
  config.value_zh_cn = "允许放置在安全位置（如大堂/信箱区）"
  config.value_zh_tw = "允許放置在安全位置（如大廳/信箱區）"
  config.value_en = "Allowed to be placed in a secure location (e.g. lobby/mailbox area)"
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_authority_to_leave_office_name", kind: :app, store_id: store.id)
  config.name = "放在门口选项名称（公司）"
  config.value_zh_cn = "放在前台"
  config.value_zh_tw = "放在前台"
  config.value_en = "Put it at the front desk"
  config.save
end
```

### 确认订单页 当面交付选项名称

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_delivered_in_person_house_name", kind: :app, store_id: store.id)
  config.name = "当面交付选项名称（住宅）"
  config.value_zh_cn = "楼下当面交付"
  config.value_zh_tw = "樓下當面交付"
  config.value_en = "Delivered in person downstairs"
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_delivered_in_person_apartment_name", kind: :app, store_id: store.id)
  config.name = "当面交付选项名称（公寓）"
  config.value_zh_cn = "楼下当面交付"
  config.value_zh_tw = "樓下當面交付"
  config.value_en = "Delivered in person downstairs"
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_delivered_in_person_office_name", kind: :app, store_id: store.id)
  config.name = "当面交付选项名称（公司）"
  config.value_zh_cn = "楼下当面交付"
  config.value_zh_tw = "樓下當面交付"
  config.value_en = "Delivered in person downstairs"
  config.save
end
```

### 确认订单页 送货上楼选项名称

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_deliver_to_door_house_name", kind: :app, store_id: store.id)
  config.name = "送货上楼选项名称（住宅）"
  config.value_zh_cn = "请把货送上楼"
  config.value_zh_tw = "請把貨送上樓"
  config.value_en = "Please deliver the goods upstairs"
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_deliver_to_door_apartment_name", kind: :app, store_id: store.id)
  config.name = "送货上楼选项名称（公寓）"
  config.value_zh_cn = "请把货送上楼"
  config.value_zh_tw = "請把貨送上樓"
  config.value_en = "Please deliver the goods upstairs"
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_deliver_to_door_office_name", kind: :app, store_id: store.id)
  config.name = "送货上楼选项名称（公司）"
  config.value_zh_cn = "请把货送上楼"
  config.value_zh_tw = "請把貨送上樓"
  config.value_en = "Please deliver the goods upstairs"
  config.save
end
```

### 确认订单页 运费说明

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_freight_fee_tip", kind: :app, store_id: store.id)
  config.name = "运费说明"
  config.value_zh_cn = "运费说明

基础派送费：订单的标准运费。不同地址的基础派送费不同，满足条件后即可免除。

指定时间段派送费：部分区域支持选择具体送达时间段。如需此服务，将在基础派送费之外加收对应费用。

超远程派送费：对于距离 eBest 仓库较远的区域，将在基础派送费之外收取一定的超远程派送费。

以上费用不同地区费用标准不同，请以APP实际显示为准。"
  config.value_zh_tw = "運費說明

基本派送費：訂單的標準運費。不同地址的基礎派送費不同，滿足條件後即可免除。

指定時段派送費：部分區域支援選擇特定送達時段。如需此服務，將在基礎派送費之外加收對應費用。

超遠端派送費：對於距離 eBest 倉庫較遠的區域，將在基礎派送費之外收取一定的超遠端派送費。

以上費用不同地區費用標準不同，請以APP實際顯示為準。"
  config.value_en = "Delivery Fee Policy

Standard Delivery Fee
This is the basic delivery charge for each order. The fee varies by delivery address and will be waived once the free-shipping threshold is met.

Preferred Time Slot Fee
In certain areas, customers can select a specific delivery time slot. An additional fee will apply on top of the Standard Delivery Fee for this service.

Remote Area Surcharge
For addresses located far from eBest’s warehouse, a Remote Area Surcharge will be added on top of the Standard Delivery Fee.

Delivery fees vary by region. Please refer to the actual charges displayed in the App for the most accurate information."
  config.save
end
```

### 确认订单页 增值服务费说明

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_value_added_service_fee_tip", kind: :app, store_id: store.id)
  config.name = "增值服务费说明"
  config.value_zh_cn = "增值服务费说明

上楼费：如需将商品送至单元门或楼层（非地面/小区门口交付），将根据您的选择收取$3上楼服务费。

超规费：箱规或大件商品数量超过XX件时，超出数量按$XX/件收取超规费用。

包装服务费：用于额外包装材料及保鲜保温物料，如纸箱、气泡膜、塑料袋、保冷袋、冰袋等。"
  config.value_zh_tw = "加值服務費說明

上樓費用：如需將商品送至單元門或樓層（非地面/小區門口交付），將根據您的選擇收取$3上樓服務費。

超規費：箱規或大件商品數量超過XX件時，超出數量按$XX/件收取超規費用。

包裝服務費：用於額外包裝材料及保鮮保溫物料，如紙箱、氣泡膜、塑膠袋、保冷袋、冰袋等。"
  config.value_en = "Value-Added Service Fees

Deliver to Door Fee
If you require your order to be delivered directly to your apartment door or a higher floor (instead of ground-level or building entrance delivery), a $3 service fee will apply based on your selection.

Heavy Item Surcharge
For oversized or heavy items, when the quantity exceeds XX units, an additional $XX per item surcharge will apply for the excess quantity.

Packing Service Fee
This fee covers the cost of additional packaging materials and temperature-control items such as cartons, bubble wrap, plastic bags, insulated bags, and ice packs."
  config.save
end
```

### 确认订单页 允许放置在门口说明

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_authority_to_leave_hourse_tip", kind: :app, store_id: store.id)
  config.name = "允许放置在门口说明（住宅）"
  config.value_zh_cn = "选择“允许放置在门口”的订单，请客户及时取走。如因无人及时收取导致货物丢失、损坏或冷冻/冷藏商品融化，平台及配送员不承担责任。"
  config.value_zh_tw = "選擇「允許放置在門口」的訂單，請客戶及時取走。如因無人及時收取導致貨物遺失、損壞或冷凍/冷藏商品融化，平台及配送員不承擔責任。"
  config.value_en = "For orders where “Authority to Leave” is selected, please ensure the parcel is collected promptly after delivery.
eBest and our delivery partners will not be responsible for any loss, damage, or spoilage (including thawing of frozen or chilled items) resulting from unattended deliveries."
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_authority_to_leave_apartment_tip", kind: :app, store_id: store.id)
  config.name = "允许放置在门口说明（公寓）"
  config.value_zh_cn = "选择“允许放置在安全位置”的订单，需客户自行确认安全性。如因无人及时收取导致货物丢失、损坏或冷冻/冷藏商品融化，平台及配送员不承担责任。"
  config.value_zh_tw = "選擇「允許放置在安全位置」的訂單，需客戶自行確認安全性。如因無人及時收取導致貨物遺失、損壞或冷凍/冷藏商品融化，平台及配送員不承擔責任。"
  config.value_en = "For orders with “Authority to Leave in a Safe Place” selected, customers are responsible for ensuring the safety of the designated location.
eBest and our delivery partners will not be liable for any loss, damage, or spoilage (including thawing of frozen or chilled items) caused by unattended deliveries."
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_authority_to_leave_office_tip", kind: :app, store_id: store.id)
  config.name = "放在前台说明（公司）"
  config.value_zh_cn = "选择“放在前台”的订单，默认视为客户已收货。如因公司内部原因造成的延误、丢失或损坏，平台及配送员不承担责任。"
  config.value_zh_tw = "選擇「放在前台」的訂單，預設視為顧客已收貨。如因公司內部原因造成的延誤、遺失或損壞，平台及配送員不承擔責任。"
  config.value_en = "For orders with “Leave at Reception” selected, the delivery will be deemed successfully received once it is handed over to the building or company reception.

eBest and our delivery partners will not be responsible for any delays, loss, or damage caused by internal handling within the building or company after delivery."
  config.save
end
```

### 确认订单页 楼下当面交付说明

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_delivered_in_person_house_tip", kind: :app, store_id: store.id)
  config.name = "楼下当面交付（住宅）"
  config.value_zh_cn = "选择“当面交付”的订单，客户需在配送员到达后立即接听电话并下楼取货，如因长时间等待（超过10分钟），导致配送失败再次派送的，每次额外征收派送费用；如因客户原因无法收货，并要求退货的，将收取一定比例的服务费。"
  config.value_zh_tw = "選擇「當面交付」的訂單，客戶需在配送員到達後立即接聽電話並下樓取貨，如因長時間等待（超過10分鐘），導致配送失敗再次派送的，每次額外徵收派送費用；如因客戶原因無法收貨，並要求退貨的，將收取一定比例的服務費。"
  config.value_en = "For orders with “Face-to-Face Delivery” selected, customers must answer the delivery call promptly and come downstairs to collect the order upon arrival.

If the driver needs to wait more than 10 minutes, the delivery will be considered unsuccessful, and an additional delivery fee will apply for each redelivery attempt.

If the order cannot be received due to customer reasons and a refund is requested, a service fee will be deducted accordingly."
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_delivered_in_person_apartment_tip", kind: :app, store_id: store.id)
  config.name = "楼下当面交付（公寓）"
  config.value_zh_cn = "选择“当面交付”的订单，客户需在配送员到达后立即接听电话并下楼取货，如因长时间等待（超过10分钟），导致配送失败再次派送的，每次额外征收派送费用；如因客户原因无法收货，并要求退货的，将收取一定比例的服务费。"
  config.value_zh_tw = "選擇「當面交付」的訂單，客戶需在配送員到達後立即接聽電話並下樓取貨，如因長時間等待（超過10分鐘），導致配送失敗再次派送的，每次額外徵收派送費用；如因客戶原因無法收貨，並要求退貨的，將收取一定比例的服務費。"
  config.value_en = "For orders with “Face-to-Face Delivery” selected, customers must answer the delivery call promptly and come downstairs to collect the order upon arrival.

If the driver needs to wait more than 10 minutes, the delivery will be considered unsuccessful, and an additional delivery fee will apply for each redelivery attempt.

If the order cannot be received due to customer reasons and a refund is requested, a service fee will be deducted accordingly."
  config.save
end

MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "order_delivered_in_person_office_tip", kind: :app, store_id: store.id)
  config.name = "楼下当面交付（公司）"
  config.value_zh_cn = "选择“当面交付”的订单，客户需在配送员到达后立即接听电话并下楼取货，如因长时间等待（超过10分钟），导致配送失败再次派送的，每次额外征收派送费用；如因客户原因无法收货，并要求退货的，将收取一定比例的服务费。"
  config.value_zh_tw = "選擇「當面交付」的訂單，客戶需在配送員到達後立即接聽電話並下樓取貨，如因長時間等待（超過10分鐘），導致配送失敗再次派送的，每次額外徵收派送費用；如因客戶原因無法收貨，並要求退貨的，將收取一定比例的服務費。"
  config.value_en = "For orders with “Face-to-Face Delivery” selected, customers must answer the delivery call promptly and come downstairs to collect the order upon arrival.

If the driver needs to wait more than 10 minutes, the delivery will be considered unsuccessful, and an additional delivery fee will apply for each redelivery attempt.

If the order cannot be received due to customer reasons and a refund is requested, a service fee will be deducted accordingly."
  config.save
end
```

### 英文网站首页顶部公告

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "web_homepage_top_notice", kind: :app, store_id: store.id)
  config.name = "英文网站首页顶部公告"
  config.value_zh_cn = "Notice"
  config.value_zh_tw = "Notice"
  config.value_en = "Notice"
  config.hint = ""
  config.save
end
```

### 满金额包邮文案

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "free_shipping_text", kind: :app, store_id: store.id)
  config.name = "满金额包邮"
  config.value_zh_cn = ""
  config.value_zh_tw = ""
  config.value_en = ""
  config.hint = ""
  config.save
end
```

### 邀请用户文案

#### 复制到剪贴板的文案

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "refer_friend_clipboard", kind: :app, store_id: store.id)
  config.name = "Share with Friends文案"
  config.value_zh_cn = "Get $90 off your first 12 orders when you join [邀请人first name] on eBest. Sign up using the link below to enjoy a better Asian grocer shopping experience.  [邀请链接]"
  config.value_zh_tw = "Get $90 off your first 12 orders when you join [邀请人first name] on eBest. Sign up using the link below to enjoy a better Asian grocer shopping experience.  [邀请链接]"
  config.value_en = "Get $90 off your first 12 orders when you join [邀请人first name] on eBest. Sign up using the link below to enjoy a better Asian grocer shopping experience.  [邀请链接]"
  config.hint = "first name 变量：{{first_name}}；邀请链接变量：{{refer_link}}"
  config.save
end
```

#### 标题

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "refer_friend_title", kind: :app, store_id: store.id)
  config.name = "邀请用户标题"
  config.value_zh_cn = ""
  config.value_zh_tw = ""
  config.value_en = "Want $10 OFF?\nGet $10 for every mate you refer"
  config.hint = "邀请用户标题"
  config.save
end
```

#### 邀请用户文字说明

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "refer_friend_content", kind: :app, store_id: store.id)
  config.name = "邀请用户文字说明"
  config.value_zh_cn = ""
  config.value_zh_tw = ""
  config.value_en = "Want Vouchers?\nGet a $5 voucher for every mate you refer and get another $5 Voucher when they order."
  config.hint = "邀请用户文字说明"
  config.save
end
```

### 新用户注册奖励文案

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "registration_promo_text", kind: :app, store_id: store.id)
  config.name = "新用户注册奖励说明"
  config.value_zh_cn = "As a new user, you'll receive 12 coupons upon registration. This includes 6 coupons for $10 off orders over $79 and 6 coupons for $5 off orders over $39. Please note that all coupons are valid for 6 months and can be used sitewide, except for products marked as ineligible on the product detail page."
  config.value_zh_tw = "As a new user, you'll receive 12 coupons upon registration. This includes 6 coupons for $10 off orders over $79 and 6 coupons for $5 off orders over $39. Please note that all coupons are valid for 6 months and can be used sitewide, except for products marked as ineligible on the product detail page."
  config.value_en = "As a new user, you'll receive 12 coupons upon registration. This includes 6 coupons for $10 off orders over $79 and 6 coupons for $5 off orders over $39. Please note that all coupons are valid for 6 months and can be used sitewide, except for products marked as ineligible on the product detail page."
  config.hint = ""
  config.save
end
```

### 可加单日期提示语

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "child_order_dates_notice", kind: :admin, store_id: store.id)
  config.name = "可加单日期提示语"
  config.value_zh_cn = "已有母单可免运费加单"
  config.value_zh_tw = "已有母單可免運費加單"
  config.value_en = ""
  config.hint = ""
  config.save
end
```

### 加单母单整单退款弹窗提示语

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "cancel_paid_parent_order_notice", kind: :admin, store_id: store.id)
  config.name = "加单母单整单退款弹窗提示语"
  config.value_zh_cn = "与母单关联的子单将一并取消并退款"
  config.value_zh_tw = "與母單關聯的子單將一併取消並退款"
  config.value_en = ""
  config.hint = ""
  config.save
end
```


### 跨境购订单下单失败发送客服通知

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "ae_order_failed_and_refund_notice", kind: :admin, store_id: store.id)
  config.name = "跨境购订单下单失败并退款的客服通知"
  config.value_zh_cn = "【eBest】亲爱的客人您好，您的订单{{no}}，由于本订单有部分商品缺货，系统已经为您自动申请退款，退款会在3个工作日内退回到您的付款账户。非常抱歉给您带来的麻烦，有任何疑问请咨询客服。"
  config.value_zh_tw = "【eBest】親愛的客人您好，您的訂單{{no}}，由於本訂單有部分商品缺貨，系統已經為您自動申請退款，退款會在3個工作日內退回到您的付款賬戶。非常抱歉給您帶來的麻煩，有任何疑問請諮詢客服。"
  config.value_en = "【eBest】Dear guest, your order {{no}}, due to the shortage of some products in this order, the system has automatically applied for a refund. The refund will be returned to your payment account within 3 working days. We apologize for any inconvenience caused. If you have any questions, please contact customer service."
  config.hint = ""
  config.save
end
```

### 跨境购确认订单页GST提示语

```ruby
MagicBean::Store.find_each do |store|
  config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "ae_order_gst_tip", kind: :app, store_id: store.id)
  config.name = "跨境购确认订单页GST提示语"
  config.value_zh_cn = "从2018年7月1日起，澳大利亚商品和服务税（GST）10%将适用于每个价值1000澳元或以下的订单，eBest有义务按照法律规定收集此类GST并汇款给澳大利亚税务局。更多信息请访问：https://www.ato.gov.au/businesses-and-organisations/international-tax-for-business/gst-on-imported-goods-and-services/australian-consumers-importing-goods-and-services"
  config.value_zh_tw = "從2018年7月1日起，澳大利亞商品和服務稅（GST）10%將適用於每個價值1,000澳元或以下的訂單，eBest有義務按照法律規定收集此類GST並匯款給澳大利亞稅務局。更多信息請訪問：https://www.ato.gov.au/businesses-and-organisations/international-tax-for-business/gst-on-imported-goods-and-services/australian-consumers-importing-goods-and-services"
  config.value_en = "From 1 July 2018, Australian goods and services tax (GST) 10% will apply to each order valued at AS1,000 or less, and eBest is required by law to collect such GST and remit to Australian Taxation Office. For more information, please visit: https://www.ato.gov.au/businesses-and-organisations/international-tax-for-business/gst-on-imported-goods-and-services/australian-consumers-importing-goods-and-services"
  config.hint = ""
  config.save
end
```

---

### 模版

```ruby
config = MagicBean::MultiLangConfig.find_or_initialize_by(key: "", kind: :admin)
config.name = ""
config.value_zh_cn = ""
config.value_zh_tw = ""
config.value_en = ""
config.hint = ""
config.save
```
