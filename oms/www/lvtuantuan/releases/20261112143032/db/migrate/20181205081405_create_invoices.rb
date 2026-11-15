# frozen_string_literal: true

class CreateInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :invoices do |t|
      t.integer :invoice_type, comment: "发票类型"
      t.string :title, comment: "抬头"
      t.string :taxpayer_id, comment: "纳税人识别号"
      t.belongs_to :order
      t.integer :amount_in_cent
      t.string :email
      t.string :remark

      t.timestamps
    end
  end
end
