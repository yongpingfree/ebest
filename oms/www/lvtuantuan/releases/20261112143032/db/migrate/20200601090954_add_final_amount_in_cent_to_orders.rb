# frozen_string_literal: true

class AddFinalAmountInCentToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :final_amount_in_cent, :integer

    say_with_time "update order final_amount_in_cent" do
      MagicBean::Order.reset_column_information
      MagicBean::Order.find_each do |oi|
        oi.final_amount_in_cent = oi.calculate_final_amount
        oi.save(validate: false)
      end
    end
  end
end
