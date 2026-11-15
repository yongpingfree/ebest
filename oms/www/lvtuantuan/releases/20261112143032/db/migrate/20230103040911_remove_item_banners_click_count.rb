# frozen_string_literal: true

class RemoveItemBannersClickCount < ActiveRecord::Migration[5.2]
  def change
    remove_column :item_banners, :click_count, :integer
  end
end
