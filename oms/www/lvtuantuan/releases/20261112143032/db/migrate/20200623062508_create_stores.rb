# frozen_string_literal: true

class CreateStores < ActiveRecord::Migration[5.2]
  def change
    create_table :stores do |t|

      t.string :name
      t.boolean :is_default, default: false
      t.timestamps
    end
  end
end
