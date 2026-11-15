# frozen_string_literal: true

class AddReturnGiftCardAmountToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :return_gift_card_amount_in_cent, :integer, default: 0
  end
end
