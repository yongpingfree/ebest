# frozen_string_literal: true

class AddGiftOnlyToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :gift_only, :boolean, comment: "只用作赠品，无法单独加购或直接购买", default: false
  end
end
