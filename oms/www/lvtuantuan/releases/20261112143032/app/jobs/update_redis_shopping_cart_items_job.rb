# frozen_string_literal: true

class UpdateRedisShoppingCartItemsJob < ApplicationJob
  queue_as :shopping_cart_items

  def perform(user, postal_code, suburb, store_id)
    MagicBean::Current.set(postal_code: postal_code, suburb: suburb, store_id: store_id) do
      # user.set_redis_store_shopping_cart_items(postal_code, suburb, true)
      # user.set_redis_store_shopping_cart_items(postal_code, suburb, false)
      user.set_redis_shopping_cart_items_delivery_time(postal_code, suburb)
    end
  end
end
