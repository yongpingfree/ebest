# frozen_string_literal: true

class AddBannersAndImageNoticeToHomepagePagingSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :homepage_paging_settings, :show_banners, :boolean, default: true
    add_column :homepage_paging_settings, :banners, :jsonb, default: {}
    add_column :homepage_paging_settings, :show_image_notice, :boolean, default: true
    add_column :homepage_paging_settings, :image_notice, :jsonb, default: {}
  end
end
