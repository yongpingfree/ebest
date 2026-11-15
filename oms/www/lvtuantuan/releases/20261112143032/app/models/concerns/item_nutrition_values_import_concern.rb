# frozen_string_literal: true

module ItemNutritionValuesImportConcern
  extend ActiveSupport::Concern

  include LoadRemoteXlsxConcern

  SKIP_ROW_OFFSET = 2
  ITEM_FIELDS = %w[serving_per_package serving_size allergen production_place]

  class_methods do
    def import_from_excel_and_notify(file_url, admin_user_id)
      admin_user = MagicBean::AdminUser.find admin_user_id
      error_messages = import_data_from_excel(file_url, admin_user)
      ItemMailer.notify_basic_import(admin_user.email, error_messages).deliver_later
      Aws::CustomOss.delete_file(file_url)
    end

    def import_data_from_excel(file_url, admin_user)
      xlsx, unsupported_file_message = try_load_remote_file(file_url)

      if xlsx.nil? && unsupported_file_message.present?
        return [unsupported_file_message]
      end

      error_messages = []
      result = xlsx.sheet(0).parse(headers: true)

      # 跳过两行表头
      result[SKIP_ROW_OFFSET..-1].each.with_index(SKIP_ROW_OFFSET + 1) do |row, idx|
        store_id = row["store_id"].to_s.strip
        item_no = row["item_no"].to_s.strip
        slug = row["slug"].to_s.strip.downcase

        # 门店或商品导入编号为空时停止处理
        break if (store_id.blank? || item_no.blank?)
        # slug为空时处理下一行数据
        next if slug.blank?

        # 处理商品数据
        item = MagicBean::Item.find_by(store_id: store_id, no: item_no)
        if item.nil?
          error_messages << "第#{idx}行：没有找到编号为 #{item_no} 的商品"
          next
        end
        item_atrrs = row.slice(*ITEM_FIELDS).compact
        item.update_columns(item_atrrs) if item_atrrs.any?

        # 处理成份数据
        nutrition = MagicBean::Nutrition.find_by(slug: slug)
        if nutrition.nil?
          error_messages << "第#{idx}行：需先添加#{row['slug']}成份基础数据，请联系技术人员"
          next
        end

        avg_qty_per_package = row["avg_qty_per_package"].to_s.strip
        avg_qty_per_100_units = row["avg_qty_per_100_units"].to_s.strip
        nutrition_attrs = {}

        if avg_qty_per_package.present?
          nutrition_attrs[:avg_qty_per_package] = avg_qty_per_package
        end

        if avg_qty_per_100_units.present?
          nutrition_attrs[:avg_qty_per_100_units] = avg_qty_per_100_units
        end

        nutrition_value = item.item_nutrition_values.find_or_initialize_by(nutrition_id: nutrition.id)
        if nutrition_attrs.any?
          nutrition_value.update(nutrition_attrs)
        else
          # 两个值都为空时删除成份
          nutrition_value.delete
        end
      end

      error_messages
    end
  end
end
