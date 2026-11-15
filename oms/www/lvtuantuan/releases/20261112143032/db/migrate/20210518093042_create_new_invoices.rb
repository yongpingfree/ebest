# frozen_string_literal: true

class CreateNewInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :invoices do |t|
      t.string :title
      t.string :abn
      t.string :first_name
      t.string :last_name
      t.string :tel_number
      t.string :address
      t.string :email
      t.belongs_to :user, foreign_key: true
      t.string :alias_name

      t.timestamps
    end
  end
end
