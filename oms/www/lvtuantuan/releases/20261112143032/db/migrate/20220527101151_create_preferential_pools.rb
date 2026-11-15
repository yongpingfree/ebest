# frozen_string_literal: true

class CreatePreferentialPools < ActiveRecord::Migration[5.2]
  def change
    create_table :preferential_pools do |t|

      t.string :title
      t.integer :kind, default: 1, comment: "优惠类型"
      t.integer :sku_ids, default: [], array: true
      t.integer :threshold_kind, default: 1, comment: "门槛类型"
      t.integer :at_least_amount_in_cent, comment: "门槛金额"
      t.integer :at_least_quantity, comment: "门槛数量"
      t.datetime :start_at, comment: "活动开始时间"
      t.datetime :end_at, comment: "活动结束时间"
      t.json :preferences, default: {}, comment: "优惠内容"
      t.boolean :enabled, default: true, comment: "是否启用"
      t.belongs_to :store

      t.timestamps
    end
  end
end
