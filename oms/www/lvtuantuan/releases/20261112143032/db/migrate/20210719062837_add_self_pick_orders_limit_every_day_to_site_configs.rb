# frozen_string_literal: true

class AddSelfPickOrdersLimitEveryDayToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :self_pick_orders_limit_every_day, :integer, default: 0
  end
end
