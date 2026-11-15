# frozen_string_literal: true

class CreateFreightTemplatesItems < ActiveRecord::Migration[5.2]
  def change
    create_table :freight_templates_items, id: false do |t|
      t.references :freight_template
      t.references :item
    end

    add_column :freight_templates, :delivery_type, :integer, default: 1
    remove_column :freight_templates, :province_ids, :integer, default: [], array: true
    add_column :freight_templates, :postal_codes, :string, default: [], array: true

    remove_column :items, :freight_template_id, :integer
  end
end
