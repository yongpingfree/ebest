class CreateDeliveryTimePeriodSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_time_period_settings do |t|
      t.belongs_to :delivery_time_period
      t.string :prefer_time
      t.integer :order_address_limit_every_day, default: 0, comment: "订单地址数上限，不受限于系统设置的地址数配送上限"
      t.integer :freight_in_cent, default: 0, comment: "运费，单位：分"

      t.timestamps
    end
  end
end
