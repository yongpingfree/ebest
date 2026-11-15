# frozen_string_literal: true

class AddBackgroundImageToHomepagePagingSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :homepage_paging_settings, :background_image, :string
  end
end
