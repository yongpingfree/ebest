# frozen_string_literal: true

class AddLiveTopToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :live_top, :boolean, default: false, comment: "直播间置顶并免邮"
    add_column :order_items, :live_top, :boolean, default: false, comment: "直播间置顶并免邮"
    add_column :shopping_cart_items, :live_top, :boolean, default: false, comment: "直播间置顶并免邮"
  end
end
