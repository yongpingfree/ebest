# frozen_string_literal: true

class CreateGiftCardTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :gift_card_templates do |t|

      t.integer :denominations_in_cent, default: 0
      t.integer :quantity, default: 0
      t.datetime :expired_at
      t.string :purchaser
      t.timestamps
    end
  end
end
