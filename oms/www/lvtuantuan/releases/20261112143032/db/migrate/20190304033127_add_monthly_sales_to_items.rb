# frozen_string_literal: true

class AddMonthlySalesToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :monthly_sales_count_offset, :integer, default: 0, null: false
    add_column :items, :actual_monthly_sales_count, :integer, default: 0, null: false
  end
end
