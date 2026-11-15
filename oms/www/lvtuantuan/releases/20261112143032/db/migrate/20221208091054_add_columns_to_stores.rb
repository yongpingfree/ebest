# frozen_string_literal: true

class AddColumnsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :default_au_suburb_id, :integer
    add_index :stores, :default_au_suburb_id
  end
end
