# frozen_string_literal: true

class AddDisplaySalesCountToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :display_sales_count, :integer, default: 0

    say_with_time "init_display_sales_count" do
      MagicBean::Item.reset_column_information
      MagicBean::Item.all.each do |item|
        item.update_columns(display_sales_count: item.calculate_display_sales_count)
      end
    end
  end
end
