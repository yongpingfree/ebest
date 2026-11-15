# frozen_string_literal: true

module ApiHelpers
  module ItemHelper
    def guess_you_like_item_ids
      # 将用户猜你喜欢计算出来的商品保存到redis, 有效期24小时
      # redis-key组成需要有当天日期 + 用户 + store + channel
      redis_key = "guess-you-like-user-#{current_user&.id}-#{MagicBean::User::GUESS_YOU_LIKE_HASH_KEY.gsub("store_id", current_store_id.to_s).gsub("channel", ebest_channel)}-#{Date.current}"
      
      guess_you_like_item_ids_str = Rails.cache.redis.get redis_key

      if guess_you_like_item_ids_str.blank?
        tmp_ids = MagicBean::Item.guess_you_like_item_ids(current_user, current_store_id, ebest_channel)
        Rails.cache.redis.set redis_key, tmp_ids.join(","), ex: 1.day
        tmp_ids
      else
        guess_you_like_item_ids_str.split(",").map(&:to_i)
      end
    end
  end
end
