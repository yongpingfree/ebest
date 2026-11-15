# frozen_string_literal: true

class AddSyncStatusToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :sync_status, :integer, default: 1, comment: "同步到 wms 状态"
  end
end
