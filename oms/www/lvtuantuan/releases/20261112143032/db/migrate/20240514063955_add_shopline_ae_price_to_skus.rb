# frozen_string_literal: true

class AddShoplineAePriceToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :shopline_price_in_cent, :integer, default: 0
    add_column :stock_keeping_units, :ae_price_in_cent, :integer, default: 0

    say_with_time "initial shopline and ae price" do
      MagicBean::Item.reset_column_information
      MagicBean::StockKeepingUnit.update_all("shopline_price_in_cent = price_in_cent, ae_price_in_cent = price_in_cent")
    end
  end
end
