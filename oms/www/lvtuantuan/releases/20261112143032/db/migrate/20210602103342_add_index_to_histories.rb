# frozen_string_literal: true

class AddIndexToHistories < ActiveRecord::Migration[5.2]
  def change
    add_index :histories, [:operatable_type, :action_type]
    add_index :histories, :action_type
    add_index :histories, [:operatable_type, :action_type, :store_id]
  end
end
