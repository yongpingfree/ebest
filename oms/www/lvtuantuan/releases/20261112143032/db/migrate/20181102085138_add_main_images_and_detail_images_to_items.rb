# frozen_string_literal: true

class AddMainImagesAndDetailImagesToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :main_images, :string, array: true, default: []
    add_column :items, :detail_images, :string, array: true, default: []
  end
end
