# frozen_string_literal: true

class CreateWarehouseOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :warehouse_orders do |t|
      t.string :no, null: false, comment: "仓储订单号，W开头"
      t.jsonb :receiver_properties, null: false, default: {}, comment: "收货人信息"
      t.integer :sync_status, null: false, default: 2, comment: "同步到 wms 状态"
      t.integer :delivery_type, null: false, comment: "配送方式"
      t.string :delivery_date, null: false, comment: "配送日期"
      t.references :user, foreign_key: true
      t.string :delivery_track, comment: "配送物流 URL"
      t.string :prefer_time, null: false, comment: "配送时间段"
      t.boolean :deliver_to_door, null: false, comment: "是否送货上门"
      t.boolean :authority_to_leave, null: false, comment: "是否无人签收"
      t.string :buyer_message, comment: "买家备注，多个销售订单买家备注拼接"
      t.string :remark, comment: "卖家备注，多个销售订单卖家备注拼接"
      t.references :store, foreign_key: true
      t.integer :channel, comment: "订单渠道"
      t.string :express_carrier, comment: "第三方邮寄派送，例如：KUAIMA"

      t.timestamps
    end
  end
end
