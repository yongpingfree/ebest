# frozen_string_literal: true

class AddFirstSaleAtToItemsAgain < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :first_sale_at, :datetime, comment: "首次上架开卖时间"
  end
end
