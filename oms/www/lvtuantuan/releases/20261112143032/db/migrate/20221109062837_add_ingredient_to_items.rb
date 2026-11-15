# frozen_string_literal: true

class AddIngredientToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :ingredient, :string
  end
end
