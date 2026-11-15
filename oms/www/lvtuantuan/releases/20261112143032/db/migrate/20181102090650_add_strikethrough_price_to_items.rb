# frozen_string_literal: true

class AddStrikethroughPriceToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :strikethrough_price, :string, comment: "商品划线价"
  end
end
