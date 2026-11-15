# frozen_string_literal: true

class AddUserLocalesToPushMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :push_messages, :user_locales, :string, array: true, default: ["zh-CN", "zh-TW"]
    remove_column :push_messages, :user_locale
  end
end
