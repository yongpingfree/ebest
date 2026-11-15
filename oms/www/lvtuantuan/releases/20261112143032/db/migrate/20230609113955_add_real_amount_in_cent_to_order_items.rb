# frozen_string_literal: true

class AddRealAmountInCentToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :real_amount_in_cent, :integer, default: 0, comment: "最终的优惠金额"

    say_with_time "init order items real_amount_in_cent" do
      MagicBean::OrderItem.reset_column_information
      MagicBean::OrderItem.update_all("real_amount_in_cent = real_price_in_cent * quantity")
    end
  end
end
