# frozen_string_literal: true

class ChangePerferTimeToPreferTimeToOrders < ActiveRecord::Migration[5.2]
  def change
    rename_column :orders, :perfer_time, :prefer_time
  end
end
