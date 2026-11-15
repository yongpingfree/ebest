# frozen_string_literal: true

class AddChannelRecentItemSearchWordsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :web_recent_item_search_words, :text, default: [], array: true, comment: 'Web最近搜索的商品关键词'
    add_column :users, :mini_program_recent_item_search_words, :text, default: [], array: true, comment: '小程序最近搜索的商品关键词'
    rename_column :users, :recent_item_search_words, :app_recent_item_search_words
    add_column :item_search_histories, :channel, :integer, default: 2, comment: '渠道, 默认app'
  end
end
