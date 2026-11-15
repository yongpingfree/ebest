# frozen_string_literal: true

class CreateKuaidiCompanyMappings < ActiveRecord::Migration[5.2]
  def change
    create_table :kuaidi_company_mappings do |t|
      t.string :cn_name, null: false
      t.string :code, null: false

      t.timestamps
    end
    add_index :kuaidi_company_mappings, :cn_name, unique: true
  end
end
