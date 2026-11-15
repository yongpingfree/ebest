# frozen_string_literal: true

class AddMarketingModeToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_column :order_items, :marketing_mode, :integer, default: 1
  end
end
