# frozen_string_literal: true

# 暂时弃用
class SyncCategoryToShoplineJob < ApplicationJob
  queue_as :shopline

  def perform(id)
    category = MagicBean::WebCategory.find(id)
    return unless category

    if category.shopline_synced?
      category.shopline_update_category
    else
      category.shopline_create_category
    end
  end
end
