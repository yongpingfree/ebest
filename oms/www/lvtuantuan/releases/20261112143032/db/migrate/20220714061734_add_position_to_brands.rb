# frozen_string_literal: true

class AddPositionToBrands < ActiveRecord::Migration[5.2]
  def change
    add_column :brands, :position, :integer, null: false, default: 999999
  end
end
