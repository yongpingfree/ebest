# frozen_string_literal: true

class ChangePingCodeToPinCode < ActiveRecord::Migration[5.2]
  def change
    rename_column :gift_card_coupons, :ping_code, :pin_code
  end
end
