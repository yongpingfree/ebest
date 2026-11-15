# frozen_string_literal: true

class AddOrderAnalysesNotifyEmailsToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :order_analyses_notify_emails, :string, array: true, default: []
  end
end
