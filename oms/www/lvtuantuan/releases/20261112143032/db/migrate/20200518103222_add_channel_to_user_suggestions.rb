# frozen_string_literal: true

class AddChannelToUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_suggestions, :channel, :integer, default: 1
  end
end
