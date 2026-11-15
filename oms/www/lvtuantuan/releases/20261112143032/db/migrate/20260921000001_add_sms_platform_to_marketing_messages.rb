# frozen_string_literal: true

class AddSmsPlatformToMarketingMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :marketing_messages, :sms_platform, :string, default: "aws", comment: "短信发送平台"
  end
end
