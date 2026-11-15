# frozen_string_literal: true

class ReindexCustomListItemsJob < ApplicationJob
  queue_as :default

  def perform(redis_key)
    es_item_ids = Rails.cache.fetch(redis_key)
    return if es_item_ids.blank?
    MagicBean::Item.where(id: es_item_ids).reindex
    Rails.cache.delete(redis_key)
  end
end
