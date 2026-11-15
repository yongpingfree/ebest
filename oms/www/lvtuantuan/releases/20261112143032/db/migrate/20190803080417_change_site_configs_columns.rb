# frozen_string_literal: true

class ChangeSiteConfigsColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_configs, :key, :string
    remove_column :site_configs, :value, :string
    remove_column :site_configs, :data_type, :string
    remove_column :site_configs, :kind, :string
    remove_column :site_configs, :description, :string

    add_column :site_configs, :return_receiver_properties, :string
    add_column :site_configs, :customer_service_name, :string
    add_column :site_configs, :sign_up_integral, :integer, default: 0
    add_column :site_configs, :suggest_integral, :integer, default: 0
    add_column :site_configs, :search_hot_words, :string, array: true, default: []
    add_column :site_configs, :web_home_banners, :json, default: []
    add_column :site_configs, :web_item_list_video, :string
    add_column :site_configs, :web_event_list_video, :string
    add_column :site_configs, :web_item_list_images, :string, array: true, default: []
    add_column :site_configs, :web_welcome_video, :string
    add_column :site_configs, :web_welcome_image, :string
    add_column :site_configs, :mall_tips, :json, dfault: {}
  end
end
