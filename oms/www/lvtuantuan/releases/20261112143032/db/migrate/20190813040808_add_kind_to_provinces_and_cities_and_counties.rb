# frozen_string_literal: true

class AddKindToProvincesAndCitiesAndCounties < ActiveRecord::Migration[5.2]
  def change
    add_column :provinces, :kind, :integer, default: 1
    add_column :cities, :kind, :integer, default: 1
    add_column :counties, :kind, :integer, default: 1
  end
end
