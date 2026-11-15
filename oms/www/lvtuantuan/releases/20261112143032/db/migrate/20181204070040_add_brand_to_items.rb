# frozen_string_literal: true

class AddBrandToItems < ActiveRecord::Migration[5.2]
  def change
    add_reference :items, :brand, index: true
  end
end
