# frozen_string_literal: true

module ItemTagsImportConcern
  extend ActiveSupport::Concern

  include LoadRemoteXlsxConcern

  SKIP_ROW_OFFSET = 2
  SEMICOLON_REGEXP = /[;；]/
  ITEM_TAGS_FIELDS = %w[
    store_id no item_tags
  ]

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
        item_no = row["no"].to_s.strip
        item_tags = row["item_tags"].to_s.strip

        # 门店或商品导入编号为空时停止处理
        break if (store_id.blank? || item_no.blank?)
        # 标签为空时处理下一行数据
        next if item_tags.blank?

        # 处理商品数据
        item = MagicBean::Item.find_by(store_id: store_id, no: item_no)
        if item.nil?
          error_messages << "第#{idx}行：没有找到编号为 #{item_no} 的商品"
          next
        end

        # 处理标签数据
        item_tags.split(SEMICOLON_REGEXP).each do |item_tag|
          item_tag_group_name, item_tag_name = item_tag.split(/[:：]/).map(&:strip)
          if item_tag_group_name.blank? || item_tag_name.blank?
            error_messages << "第#{idx}行：有标签组和标签组存在空值"
            next
          end

          item_tag_group = MagicBean::ItemTagGroup.ransack(translations_name_eq: item_tag_group_name).result.first
          if item_tag_group.blank?
            error_messages << "第#{idx}行：找不到标签组 #{item_tag_group_name}"
            next
          end

          item_tag = item_tag_group.item_tags.ransack(translations_name_eq: item_tag_name).result.first
          if item_tag.blank?
            item_tag = item_tag_group.item_tags.create!(name_zh_cn: item_tag_name)
          end

          item.item_tag_relations.find_or_create_by!(item_tag_id: item_tag.id)
        end
      end

      error_messages
    end
  end
end
