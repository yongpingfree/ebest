# frozen_string_literal: true

class AddLikesCountOffsetToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :likes_count_offset, :integer, null: false, default: 0
  end
end
