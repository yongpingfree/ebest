# frozen_string_literal: true

class AddStoreIdsToGiftCards < ActiveRecord::Migration[5.2]
  def change
    add_column :gift_card_templates, :store_ids, :integer, default: [], array: true
    add_column :gift_card_coupons, :store_ids, :integer, default: [], array: true
  end
end
