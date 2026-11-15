# frozen_string_literal: true

class AddStockKeepingUnitIdAndPropertiesTextToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :stock_keeping_unit_id, :integer
    add_column :comments, :properties_text, :string
  end
end
