# frozen_string_literal: true

class AddDescriptionToSiteConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :description, :string
  end
end
