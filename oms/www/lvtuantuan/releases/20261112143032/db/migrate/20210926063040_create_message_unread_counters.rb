# frozen_string_literal: true
class CreateMessageUnreadCounters < ActiveRecord::Migration[5.2]
  def change
    create_table :message_unread_counters do |t|
      t.references :user, foreign_key: true
      t.integer :order_tracking_count, default: 0, null: false, comment: "订单追踪未读消息数"
      t.integer :customer_service_count, default: 0, null: false, comment: "客服通知未读消息数"

      t.timestamps
    end
  end
end
