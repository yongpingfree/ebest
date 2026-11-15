# frozen_string_literal: true

class CreateLogistics < ActiveRecord::Migration[5.2]
  def change
    create_table :logistics do |t|
      t.string :no
      t.string :company
      t.jsonb :traces
      t.string :remark, comment: "备注(用于多个物流单时备注该物流单包含的商品)"
      t.references :order

      t.timestamps
    end

    add_index :logistics, :no, unique: true
  end
end
