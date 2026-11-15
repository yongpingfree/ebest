# frozen_string_literal: true

class AddIntegralSpecialPeriodRuleToSiteConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :integral_special_period_rule, :json, default: {}
  end
end
