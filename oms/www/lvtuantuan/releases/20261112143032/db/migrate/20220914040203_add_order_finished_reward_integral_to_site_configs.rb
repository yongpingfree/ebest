# frozen_string_literal: true

class AddOrderFinishedRewardIntegralToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_finished_reward_integral, :boolean, default: true
    add_column :orders, :order_finished_reward_integral, :boolean, default: true
  end
end
