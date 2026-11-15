# frozen_string_literal: true

class AddChannelToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :channel, :integer, default: 0
  end
end
