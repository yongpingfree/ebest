# frozen_string_literal: true

class AddOriginalAmountInCentToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :original_amount_in_cent, :integer
  end
end
