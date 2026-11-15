#frozen_string_literal: true

class ChangeNeedAtLeastAmountComment < ActiveRecord::Migration[5.2]
  def change
    change_column :coupon_templates, :need_at_least_amount, :boolean, comment: "是否有门槛使用"
  end
end
