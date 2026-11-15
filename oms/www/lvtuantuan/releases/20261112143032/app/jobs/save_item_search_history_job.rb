# frozen_string_literal: true

class SaveItemSearchHistoryJob < ApplicationJob
  queue_as :low_priority

  def perform(*)
    keys = Rails.cache.redis.keys "item_history_user_*"
    return if keys.blank?
    keys.each do |key|
      user_id, channel = key.gsub("item_history_user_", "").split("-")
      # 旧的redis key没有加channel, 为了兼容，如果没有channel，就默认为app
      channel = "app" if channel.blank?

      # 有的用户会被合并，可能出现找不到用户的情况
      user = MagicBean::User.find_by id: user_id
      if user.blank?
        Rails.cache.redis.del(key)
        next
      end
      search_words = Rails.cache.redis.lrange key, 0, -1

      words = (search_words.first(MagicBean::User::RECENT_ITEM_WORDS_LENGTH) + user.send("#{channel}_recent_item_search_words")).uniq.first(MagicBean::User::RECENT_ITEM_WORDS_LENGTH)
      user.update_column("#{channel}_recent_item_search_words", words)
      search_words.each do |word|
        # 任务将在凌晨跑，记录的日期为前一天日期
        MagicBean::ItemSearchHistory.find_or_create_by(word: word, search_date: Date.current.yesterday, user: user, channel: channel)
        Rails.cache.redis.lrem(key, 0, word)
      end
    end
  end
end
