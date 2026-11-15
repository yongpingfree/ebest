# frozen_string_literal: true
class AddCanCreateInvoiceToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :can_create_invoice, :boolean, default: true
  end
end
