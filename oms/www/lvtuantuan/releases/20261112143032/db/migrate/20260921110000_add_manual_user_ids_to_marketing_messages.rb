# frozen_string_literal: true

class AddManualUserIdsToMarketingMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :marketing_messages, :manual_user_ids, :integer, default: [], array: true, comment: "手动添加用户"
  end
end
