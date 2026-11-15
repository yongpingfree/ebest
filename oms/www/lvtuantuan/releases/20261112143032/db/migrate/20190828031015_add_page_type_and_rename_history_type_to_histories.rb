# frozen_string_literal: true

class AddPageTypeAndRenameHistoryTypeToHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :histories, :page_type, :integer, default: 1
    rename_column :histories, :history_type, :action_type
  end
end
