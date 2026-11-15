# frozen_string_literal: true

class RemoveOriginPriceInCentInItems < ActiveRecord::Migration[5.2]
  def change
    remove_column :items, :origin_price_in_cent, :integer, default: 0
  end
end
