# frozen_string_literal: true
class AddItemsCountToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :items_count, :integer, default: 0

    say_with_time "update items count" do
      MagicBean::Product.reset_column_information
      MagicBean::Product.find_each do |product|
        MagicBean::Product.reset_counters(product.id, :items)
      end
    end
  end
end
