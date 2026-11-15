# frozen_string_literal: true

class AddSkuNosToLogistics < ActiveRecord::Migration[5.2]
  def change
    add_column :logistics, :sku_ids, :integer, array: true, default: []
  end
end
