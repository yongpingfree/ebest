# frozen_string_literal: true

class AddDefaultValueToStringArray < ActiveRecord::Migration[5.2]
  def change
    change_column_default :web_items, :upper_images, []
    change_column_default :web_items, :lower_images, []
    change_column_default :web_items, :banner_images, []
  end
end
