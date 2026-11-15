# frozen_string_literal: true

class CalculateGuessYouLikeJob < ApplicationJob
  queue_as :default

  def perform
    MagicBean::User.where(is_blocked: false).each do |user|
      guess_you_like_item_ids_hash = {}
      MagicBean::Store.all.each do |store|
        MagicBean::Item::CHANNEL_ARRAY.each do |channel|
          key = MagicBean::User::GUESS_YOU_LIKE_HASH_KEY.gsub("store_id", store.id.to_s).gsub("channel", channel)
          guess_you_like_item_ids_hash[key] = MagicBean::Item.guess_you_like_item_ids(user, store.id, channel)
        end
      end
      user.update_columns(guess_you_like_item_ids_hash: guess_you_like_item_ids_hash)
    end
  end
end
