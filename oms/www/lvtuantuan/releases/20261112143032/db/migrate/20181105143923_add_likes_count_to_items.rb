# frozen_string_literal: true

class AddLikesCountToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :likes_count, :integer, default: 0
  end
end
