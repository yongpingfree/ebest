# frozen_string_literal: true

class AddImagesToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :images, :string, array: true, default: []
  end
end
