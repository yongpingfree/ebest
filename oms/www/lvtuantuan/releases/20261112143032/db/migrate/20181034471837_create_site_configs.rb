# frozen_string_literal: true

class CreateSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :site_configs do |t|
      t.string :key
      t.string :value
      t.integer :data_type, default: 1

      t.timestamps
    end
  end
end
