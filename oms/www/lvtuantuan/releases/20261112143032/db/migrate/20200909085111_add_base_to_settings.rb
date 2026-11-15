# frozen_string_literal: true
class AddBaseToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :base, :json, default: {}
  end
end
