# frozen_string_literal: true

class AddUserLocaleToPushMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :push_messages, :user_locale, :string, default: "zh-CN"
  end
end
