# frozen_string_literal: true

class AddBuyQuotaDaysToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :buy_quota_days, :integer, default: 0
  end
end
