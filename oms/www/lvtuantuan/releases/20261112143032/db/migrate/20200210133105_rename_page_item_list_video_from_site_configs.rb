# frozen_string_literal: true

class RenamePageItemListVideoFromSiteConfigs < ActiveRecord::Migration[5.2]
  def up
    remove_column :site_configs, :web_item_list_video
    remove_column :site_configs, :web_event_list_video
    remove_column :site_configs, :web_welcome_video

    rename_column :site_configs, :page_item_list_video, :web_item_list_video
    rename_column :site_configs, :page_event_list_video, :web_event_list_video
    rename_column :site_configs, :page_welcome_video, :web_welcome_video
  end

  def down
    rename_column :site_configs, :web_item_list_video, :page_item_list_video
    rename_column :site_configs, :web_event_list_video, :page_event_list_video
    rename_column :site_configs, :web_welcome_video, :page_welcome_video

    add_column :site_configs, :web_item_list_video, :string
    add_column :site_configs, :web_event_list_video, :string
    add_column :site_configs, :web_welcome_video, :string
  end
end
