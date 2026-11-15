# frozen_string_literal: true

class AddShowDiscountRateToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :show_discount_rate, :boolean, default: false
  end
end
