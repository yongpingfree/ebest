# frozen_string_literal: true

class AddPingCodeToGiftCardCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :gift_card_coupons, :ping_code, :string
  end
end
