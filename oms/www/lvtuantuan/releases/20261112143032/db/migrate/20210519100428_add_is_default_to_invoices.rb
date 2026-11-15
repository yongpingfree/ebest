# frozen_string_literal: true

class AddIsDefaultToInvoices < ActiveRecord::Migration[5.2]
  def change
    add_column :invoices, :is_default, :boolean, default: false
  end
end
