# frozen_string_literal: true

class RemoveChannelFromItems < ActiveRecord::Migration[5.2]
  def change
    remove_column :items, :channel, :integer
  end
end
