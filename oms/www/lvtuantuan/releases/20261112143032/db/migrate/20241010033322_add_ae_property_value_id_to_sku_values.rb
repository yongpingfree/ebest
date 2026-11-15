# frozen_string_literal: true

class AddAePropertyValueIdToSkuValues < ActiveRecord::Migration[5.2]
  def change
    add_column :sku_values, :ae_property_value_id, :string
    add_column :sku_properties, :ae_property_id, :string
  end
end
