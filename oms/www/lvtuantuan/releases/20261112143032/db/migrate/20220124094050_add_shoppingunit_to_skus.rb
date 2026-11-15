# frozen_string_literal: true

class AddShoppingunitToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :shoppingunit, :string, comment: "入驻商"
  end
end
