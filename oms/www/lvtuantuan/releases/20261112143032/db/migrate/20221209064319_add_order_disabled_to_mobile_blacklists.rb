# frozen_string_literal: true

class AddOrderDisabledToMobileBlacklists < ActiveRecord::Migration[5.2]
  def change
    add_column :mobile_blacklists, :order_disabled, :boolean, default: true
    rename_column :mobile_blacklists, :comment_disabled, :live_comment_disabled
    rename_column :mobile_blacklists, :lottery_disabled, :live_lottery_disabled
  end
end
