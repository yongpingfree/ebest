# frozen_string_literal: true

class AddAcceptMarketingMessageToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :accept_marketing_message, :boolean, default: true, comment: "是否接收营销短信"
  end
end
