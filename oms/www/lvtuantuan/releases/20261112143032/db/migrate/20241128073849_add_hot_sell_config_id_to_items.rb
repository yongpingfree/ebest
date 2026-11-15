# frozen_string_literal: true

class AddHotSellConfigIdToItems < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :items, :hot_sell_config
  end
end
