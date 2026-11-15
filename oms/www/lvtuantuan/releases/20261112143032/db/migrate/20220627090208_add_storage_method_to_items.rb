# frozen_string_literal: true

class AddStorageMethodToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :storage_method, :integer, default: 0
  end
end
