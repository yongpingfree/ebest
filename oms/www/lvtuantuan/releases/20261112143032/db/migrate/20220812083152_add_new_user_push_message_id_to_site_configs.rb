# frozen_string_literal: true

class AddNewUserPushMessageIdToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :new_user_custom_page_id, :integer
    add_column :site_configs, :new_user_message_text, :text
  end
end
