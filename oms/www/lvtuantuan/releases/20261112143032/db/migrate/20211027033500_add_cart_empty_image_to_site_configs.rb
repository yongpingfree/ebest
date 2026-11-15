# frozen_string_literal: true

class AddCartEmptyImageToSiteConfigs < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :cart_empty_image, :string
  end
end
