# frozen_string_literal: true

class CreateSkuSalesMailerSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_sales_mailer_settings do |t|
      t.string :title, comment: "邮件标题"
      t.string :receiver_emails, comment: "接收邮件的邮箱，多个邮箱用分号分隔"
      t.string :cc_emails, comment: "抄送邮件的邮箱，多个邮箱用分号分隔"
      t.integer :deliver_after_n_days, comment: "N天后发货的统计，例：设置1则统计发货日期为一天后的数据"
      t.boolean :contains_order_gift, comment: "是否包含订单赠品"
      t.boolean :contains_order_pool_gift, comment: "是否包含订单池赠品"
      t.string :send_at, comment: "发送时间，格式：HH:MM:SS"
      t.integer :send_frequency, comment: "发送频率，1: 单次，2: 每天，3: 每周"
      t.string :weekdays, array: true, default: [], comment: "每周发送的日期，0: 周日, 1: 周一，2: 周二，3: 周三，4: 周四，5: 周五，6: 周六"
      t.integer :sku_search_type, comment: "sku搜索类型，1: 根据条件，2: 根据sku_ids"
      t.json :sku_search_conditions, default: {}, comment: "sku搜索条件"
      t.integer :sku_ids, array: true, default: []
      t.boolean :enabled, comment: "是否启用", default: false
      t.belongs_to :store, comment: "店铺"
      
      t.timestamps
    end
  end
end
