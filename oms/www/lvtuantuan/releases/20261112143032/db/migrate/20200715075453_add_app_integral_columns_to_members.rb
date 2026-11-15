# frozen_string_literal: true

class AddAppIntegralColumnsToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :app_available_integral, :integer, default: 0, comment: "APP 可用积分"
    add_column :members, :app_blocked_integral, :integer, default: 0, comment: "APP 冻结积分"
    add_column :members, :app_cumulative_integral, :integer, default: 0, comment: "APP 累积获取积分"
  end
end
