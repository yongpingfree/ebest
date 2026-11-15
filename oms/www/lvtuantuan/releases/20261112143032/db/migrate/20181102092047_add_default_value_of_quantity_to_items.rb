# frozen_string_literal: true

class AddDefaultValueOfQuantityToItems < ActiveRecord::Migration[5.2]
  def change
    change_column_default :items, :quantity, 0
    change_column_null :items, :quantity, false
  end
end
