class CreateThirdPartyOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :third_party_orders do |t|

      t.integer :third_party_type, comment: "第三方平台类型: 1: shopline, 2: aliexpress"
      t.string :third_party_id, comment: "第三方平台订单id"
      t.string :no, comment: "第三方平台订单号"
      t.string :status, comment: "状态: open 处理中，cancelled 已取消"
      t.string :financial_status, comment: "支付状态"
      t.string :fulfillment_status, comment: "发货状态"
      t.integer :delivery_type, default: 1
      t.integer :sync_status, default: 1, comment: "同步到 wms 状态"
      t.datetime :synced_at, comment: "同步到 wms 时间"
      t.string :delivery_date, comment: "配送日期"
      t.string :prefer_time, comment: "配送时间段"
      t.decimal :order_total, precision: 10, scale: 2, comment: "订单支付金额"
      t.decimal :total_discounts, precision: 10, scale: 2, comment: "折扣金额"
      t.decimal :total_line_items_price, precision: 10, scale: 2, comment: "商品总价"
      t.jsonb :order_items, comment: "订单商品"
      t.jsonb :payment_details, comment: "支付详情", default: {}
      t.jsonb :receiver_properties, default: {}, null: false, comment: "收货人信息"
      t.string :buyer_message, comment: "买家留言"
      t.jsonb :shipping_lines, default: {}, null: false, comment: "运费信息"

      t.timestamps
    end
  end
end
