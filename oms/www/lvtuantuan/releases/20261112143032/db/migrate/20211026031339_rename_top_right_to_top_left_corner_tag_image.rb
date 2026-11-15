# frozen_string_literal: true
class RenameTopRightToTopLeftCornerTagImage < ActiveRecord::Migration[5.2]
  def change
    rename_column :items, :top_right_corner_tag_image, :top_left_corner_tag_image
  end
end
