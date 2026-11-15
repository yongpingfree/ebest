# frozen_string_literal: true

class AddRepliedAtToUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_suggestions, :replied_at, :datetime
  end
end
