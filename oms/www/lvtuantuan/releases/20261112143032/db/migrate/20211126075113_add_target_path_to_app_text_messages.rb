# frozen_string_literal: true
class AddTargetPathToAppTextMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :app_text_messages, :target_type, :string
    add_column :app_text_messages, :target_id, :bigint
  end
end
