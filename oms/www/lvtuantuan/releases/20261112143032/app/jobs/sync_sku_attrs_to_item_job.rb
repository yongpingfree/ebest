# frozen_string_literal: true

class SyncSkuAttrsToItemJob < ApplicationJob
  queue_as :default

  def perform(id)
    item = MagicBean::Item.find_by id: id
    return if item.nil?

    item.sync_sku_attrs
  end
end
