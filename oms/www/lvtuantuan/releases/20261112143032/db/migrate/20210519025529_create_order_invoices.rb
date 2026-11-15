# frozen_string_literal: true

class CreateOrderInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :order_invoices do |t|
      t.string :no
      t.belongs_to :order, foreign_key: true, index: false
      t.integer :state, default: 0
      t.hstore :invoice_properties

      t.timestamps
    end

    add_index(:order_invoices, :no, unique: true)
    add_index(:order_invoices, :order_id, unique: true)
  end
end
