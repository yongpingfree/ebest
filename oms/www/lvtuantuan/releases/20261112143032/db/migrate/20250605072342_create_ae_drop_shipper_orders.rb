# frozen_string_literal: true

class CreateAeDropShipperOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :ae_drop_shipper_orders do |t|
      t.belongs_to :order
      t.string :ae_order_no
      t.string :order_paidtime
      t.string :gmt_create, comment: "AE订单创建时间"
      t.string :order_status
      t.string :logistics_status
      t.decimal :order_amount, precision: 12, scale: 2, comment: "订单总金额, 单位: AUD"
      t.jsonb :child_order_list, comment: "订单项信息", default: []
      t.jsonb :store_info, comment: "AE店铺信息", default: {}

      t.timestamps
    end
  end
end
