# frozen_string_literal: true

class AddMarketingModeToSkus < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_keeping_units, :marketing_mode, :integer, default: 1
  end
end
