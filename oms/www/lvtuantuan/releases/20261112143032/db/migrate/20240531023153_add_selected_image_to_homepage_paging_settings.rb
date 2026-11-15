# frozen_string_literal: true

class AddSelectedImageToHomepagePagingSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :homepage_paging_settings, :selected_image, :string, comment: "选中图片"
  end
end
