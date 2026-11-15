# frozen_string_literal: true

class AddFreightToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :fixed_freight, :integer, comment: "统一运费"
    add_column :items, :freight_type, :integer, null: false, default: 1
    add_reference :items, :freight_template, foreign_key: true
  end
end
