# frozen_string_literal: true

class DropInvoices < ActiveRecord::Migration[5.2]
  def change
    drop_table :invoices
  end
end
