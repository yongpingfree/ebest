# frozen_string_literal: true

class AddGiftCardEnabledToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :gift_card_enabled, :boolean, default: true
  end
end
