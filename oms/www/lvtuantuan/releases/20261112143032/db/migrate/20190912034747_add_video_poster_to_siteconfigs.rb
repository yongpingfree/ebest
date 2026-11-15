
# frozen_string_literal: true

class AddVideoPosterToSiteconfigs < ActiveRecord::Migration[5.2]
  def up
    add_column :site_configs, :page_item_list_video, :json, default: {}
    add_column :site_configs, :page_event_list_video, :json, default: {}
    add_column :site_configs, :page_welcome_video, :json, default: {}

    say_with_time "update site config video poster" do
      MagicBean::SiteConfig.reset_column_information
      config = MagicBean::SiteConfig.default_config
      return if config.nil?
      config.page_item_list_video = {
        src: config.web_item_list_video,
        poster: ""
      }

      config.page_event_list_video = {
        src: config.web_event_list_video,
        poster: ""
      }

      config.page_welcome_video = {
        src: config.web_welcome_video,
        poster: ""
      }

      config.save!(validate: false)
    end

    remove_column :site_configs, :web_item_list_video
    remove_column :site_configs, :web_event_list_video
    remove_column :site_configs, :web_welcome_video

    rename_column :site_configs, :page_item_list_video, :web_item_list_video
    rename_column :site_configs, :page_event_list_video, :web_event_list_video
    rename_column :site_configs, :page_welcome_video, :web_welcome_video
  end

  def down
    add_column :site_configs, :page_item_list_video, :string
    add_column :site_configs, :page_event_list_video, :string
    add_column :site_configs, :page_welcome_video, :string

    say_with_time "update site config video poster" do
      MagicBean::SiteConfig.reset_column_information
      config = MagicBean::SiteConfig.default_config
      return if config.nil?
      config.page_item_list_video = config.web_item_list_video.dig("src")

      config.page_event_list_video = config.web_event_list_video.dig("src")

      config.page_welcome_video = config.web_welcome_video.dig("src")

      config.save!(validate: false)
    end

    remove_column :site_configs, :web_item_list_video
    remove_column :site_configs, :web_event_list_video
    remove_column :site_configs, :web_welcome_video

    rename_column :site_configs, :page_item_list_video, :web_item_list_video
    rename_column :site_configs, :page_event_list_video, :web_event_list_video
    rename_column :site_configs, :page_welcome_video, :web_welcome_video
  end
end
