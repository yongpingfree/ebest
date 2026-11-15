# frozen_string_literal: true

class AddHotSellRankingToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :hot_sell_ranking, :integer
  end
end
