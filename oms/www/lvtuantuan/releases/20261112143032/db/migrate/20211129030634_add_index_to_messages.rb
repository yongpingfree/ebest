# frozen_string_literal: true

class AddIndexToMessages < ActiveRecord::Migration[5.2]
  def change
    add_index :push_messages, [:path_customized_id, :path_customized_type], name: "index_push_messages_on_path_customized_attrs"
    add_index :app_text_messages, [:target_id, :target_type], name: "index_app_text_messages_on_target_attrs"
  end
end
