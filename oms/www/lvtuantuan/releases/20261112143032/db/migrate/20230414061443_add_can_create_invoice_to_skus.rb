# frozen_string_literal: true

class AddCanCreateInvoiceToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :can_create_invoice, :boolean, default: true
  end
end
