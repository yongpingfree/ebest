# frozen_string_literal: true

class AddIsSentButStatusNotShowToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :is_sent_but_status_not_show, :boolean, default: false
    add_column :orders, :apply_reason, :string
  end
end
