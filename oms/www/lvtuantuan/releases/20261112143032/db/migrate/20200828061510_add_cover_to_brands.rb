# frozen_string_literal: true

class AddCoverToBrands < ActiveRecord::Migration[5.2]
  def change
    add_column :brands, :cover, :string
  end
end
