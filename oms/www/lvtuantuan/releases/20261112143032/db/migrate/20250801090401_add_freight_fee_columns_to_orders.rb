# frozen_string_literal: true

class AddFreightFeeColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :long_distance_fee_in_cent, :integer, default: 0, comment: "远程运费"
    add_column :orders, :time_period_fee_in_cent, :integer, default: 0, comment: "指定时间段运费"
    add_column :orders, :box_regulation_fee_in_cent, :integer, default: 0, comment: "超出箱规费用"
    add_column :orders, :box_regulation_quantity, :integer, default: 0, comment: "箱规数量"
    add_column :orders, :free_box_regulation_quantity, :integer, default: 0, comment: "免费箱规数量"
    add_column :orders, :per_box_charge_in_cent, :integer, default: 0, comment: "每个箱规费用"
  end
end
