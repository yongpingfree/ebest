# frozen_string_literal: true

class AddAeIdToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ae_category_id, :string, index: true
    add_column :items, :ae_product_attributes, :jsonb
  end
end
