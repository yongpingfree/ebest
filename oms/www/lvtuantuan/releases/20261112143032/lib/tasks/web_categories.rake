# frozen_string_literal: true

namespace :web_categories do
  desc "从 Category 复制数据到 WebCategory"
  task copy_from_categories: :environment do
    MagicBean::Category.includes(:translations).find_each do |category|
      web_category = MagicBean::WebCategory.find_or_initialize_by(id: category.id)

      params = category.attributes.except("id", "created_at", "updated_at", "sort_item_ids", "item_position", "show_on_web", "goto_kind")
      web_category.assign_attributes(params)
      web_category.name_en = category.name_en
      web_category.name_zh_tw = category.name_zh_tw
      web_category.name_zh_cn = category.name_zh_cn

      web_category.save
    end

    # NOTE: 执行后需到数据库里执行 `SELECT setval('web_categories_id_seq', (SELECT max(id) FROM web_categories));` 重置 id 自增序列
  end

  desc "更新已有商品的 WebCategory 数据"
  task update_items_web_categories: :environment do
    MagicBean::Item.find_each do |item|
      item.update_columns(web_category_id: item.category_id, minor_web_category_id: item.minor_category_id)
    end
  end
end
