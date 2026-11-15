# frozen_string_literal: true

class AddReplyToUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_suggestions, :reply, :text
  end
end
