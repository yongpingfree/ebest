# frozen_string_literal: true

class AddTimeKindToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :time_kind, :integer, default: 1
  end
end
