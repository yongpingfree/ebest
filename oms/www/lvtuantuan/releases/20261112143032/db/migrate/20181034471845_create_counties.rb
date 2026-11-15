# frozen_string_literal: true

class CreateCounties < ActiveRecord::Migration[5.2]
  def change
    create_table :counties do |t|
      t.string :name, null: false
      t.references :city, foreign_key: true

      t.timestamps
    end
  end
end
