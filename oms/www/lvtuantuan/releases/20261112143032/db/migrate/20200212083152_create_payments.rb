# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[5.1]
  def change
    create_table :payments do |t|
      t.string :transaction_id
      t.decimal :amount_in_cent, precision: 12, scale: 2
      t.string :type
      t.belongs_to :paymentable, polymorphic: true
      t.integer :status, default: 1
      t.integer :payment_type, default: 1
      t.json :response, default: {}
      t.belongs_to :parent
      t.decimal :refund_amount_in_cent, precision: 12, scale: 2, default: "0.0"
      t.decimal :refunding_amount_in_cent, precision: 12, scale: 2, default: "0.0"
      t.decimal :service_amount_in_cent, precision: 12, scale: 2, default: "0.0"
      t.datetime :completed_at

      t.timestamps
    end

    add_index :payments, :transaction_id
  end
end
