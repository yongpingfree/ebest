# frozen_string_literal: true
class CreateSuppliers < ActiveRecord::Migration[5.2]
  def change
    create_table :suppliers do |t|
      t.string :name, desc: "供应商名称"
      t.integer :cost_in_cent, desc: "供应商价格"
      t.references :stock_keeping_unit

      t.timestamps
    end
  end
end
