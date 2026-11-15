# frozen_string_literal: true

class AddAeDropShipperToCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :ae_drop_shipper, :boolean, default: false
    add_column :categories, :ae_drop_shipper_category_id, :string

    add_index :categories, :ae_drop_shipper_category_id
  end
end
