# frozen_string_literal: true

class CreateFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :freight_templates do |t|
      t.string :name, null: false
      t.integer :first_kg_charge_in_cent, null: false, comment: "1KG以内运费"
      t.integer :second_kg_charge_in_cent, null: false, comment: "2KG以内运费"
      t.integer :continued_weight_charge_in_cent, null: false, comment: "超过2KG后每KG运费，不足1KG按1KG算"
      t.integer :extra_charge_in_cent, null: false, default: 0, comment: "超过2KG后一次性的额外费用"
      t.string :type, null: false
      t.integer :province_ids, array: true, default: []
      t.references :freight_template

      t.timestamps
    end
  end
end
