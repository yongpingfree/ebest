# frozen_string_literal: true

class CreateUserHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :user_histories do |t|

      t.belongs_to :user
      t.belongs_to :operatable, polymorphic: true
      t.date :view_date
      t.integer :count, default: 0
      t.integer :channel, default: 1
      t.timestamps
    end
  end
end
