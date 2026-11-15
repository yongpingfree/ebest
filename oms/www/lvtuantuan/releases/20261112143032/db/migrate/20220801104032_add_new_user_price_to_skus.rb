# frozen_string_literal: true

class AddNewUserPriceToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :new_user_price_in_cent, :integer
    add_column :stock_keeping_units, :new_user_buy_quota, :integer, default: 0, comment: "新人限购数量，0为不限"
  end
end
