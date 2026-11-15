# frozen_string_literal: true

class AddChannelToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :channel, :integer, default: 1
  end
end
