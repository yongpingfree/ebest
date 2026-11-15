# frozen_string_literal: true

class ChangeOrderAudToCnyExchangeRateScale < ActiveRecord::Migration[5.2]
  def change
    change_column :orders, :aud_to_cny_exchange_rate, :decimal, precision: 12, scale: 4, default: "0.0"
  end
end
