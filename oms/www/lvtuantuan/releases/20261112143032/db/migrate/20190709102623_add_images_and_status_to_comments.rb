# frozen_string_literal: true

class AddImagesAndStatusToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :images, :text, array: true, default: []
    add_column :comments, :status, :integer, default: 1
  end
end
