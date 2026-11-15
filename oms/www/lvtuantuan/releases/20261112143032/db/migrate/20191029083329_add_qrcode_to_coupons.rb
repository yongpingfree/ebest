# frozen_string_literal: true

class AddQrcodeToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :qrcode, :string
  end
end
