# frozen_string_literal: true

class CreateItemSearchHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :item_search_histories do |t|
      t.string :word
      t.date :search_date
      t.belongs_to :user

      t.timestamps
    end
  end
end
