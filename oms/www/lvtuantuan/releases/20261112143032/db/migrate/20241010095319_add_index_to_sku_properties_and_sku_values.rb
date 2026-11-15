# frozen_string_literal: true

class AddIndexToSkuPropertiesAndSkuValues < ActiveRecord::Migration[5.2]
  def change
    add_index :sku_properties, :ae_property_id
    add_index :sku_values, [:sku_property_id, :ae_property_value_id]
  end
end
