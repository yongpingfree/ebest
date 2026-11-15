# frozen_string_literal: true

class AddItemIdAndUserKindToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :item_ids, :integer, array: true, default: []
  end
end
