# frozen_string_literal: true

class AddPurposeToGiftCardTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :gift_card_templates, :purpose, :integer, default: 1
  end
end
