# frozen_string_literal: true

class AddTopRightCornerTagImageToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :top_right_corner_tag_image, :string
  end
end
