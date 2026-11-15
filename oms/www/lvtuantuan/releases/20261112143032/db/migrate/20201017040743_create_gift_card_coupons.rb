# frozen_string_literal: true

class CreateGiftCardCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :gift_card_coupons do |t|

      t.belongs_to :gift_card_template
      t.string :code
      t.integer :denominations_in_cent, default: 0
      t.integer :used_amount_in_cent, default: 0
      t.integer :status, default: 1
      t.datetime :expired_at
      t.timestamps
    end
  end
end
