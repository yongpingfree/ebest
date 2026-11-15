# frozen_string_literal: true

class AddChannelToPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :channel, :integer, default: 1
  end
end
