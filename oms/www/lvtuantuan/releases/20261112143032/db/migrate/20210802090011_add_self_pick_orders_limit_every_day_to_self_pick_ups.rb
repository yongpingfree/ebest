# frozen_string_literal: true

class AddSelfPickOrdersLimitEveryDayToSelfPickUps < ActiveRecord::Migration[5.2]
  def change
    add_column :self_pick_ups, :self_pick_orders_limit_every_day, :integer, default: 0
    remove_column :site_configs, :self_pick_orders_limit_every_day, :integer
  end
end
