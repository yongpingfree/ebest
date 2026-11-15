# frozen_string_literal: true

class AddChannelToOrdersAndGroupons < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :channel, :integer, default: 1
    add_column :groupons, :channel, :integer, default: 1
  end
end
