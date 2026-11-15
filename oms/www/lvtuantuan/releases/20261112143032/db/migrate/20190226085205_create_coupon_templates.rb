# frozen_string_literal: true

class CreateCouponTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :coupon_templates do |t|
      t.string :title
      t.string :desc, comment: "使用说明"
      t.integer :kind, default: 1
      t.integer :denominations_in_cent, comment: "面额（单位：分）"
      t.float :discount
      t.integer :at_least_amount_in_cent, comment: "订单满减金额"
      t.boolean :need_at_least_amount, comment: "是否无门槛使用"
      t.integer :time_kind, default: 1, comment: "用券时间类型"
      t.integer :time_limit_in_day, default: 0, comment: " 领取后限时使用 0 表示无限"
      t.datetime :start_at, comment: "开始时间（可以开始使用优惠券）"
      t.datetime :end_at, comment: "结束时间（不能再使用优惠券）"
      t.string :details_image
      t.string :expired_image
      t.string :ticket_image
      t.boolean :enabled, comment: "是否启用优惠券"
      t.string :remarks
      t.string :code, comment: "优惠券码"
      t.integer :users_count, default: 0
      t.integer :orders_count, default: 0

      t.timestamps
    end
  end
end
