# frozen_string_literal: true
class AddImagesToUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :user_suggestions, :images, :string, array: true, default: []
  end
end
