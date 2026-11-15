# frozen_string_literal: true

module SkuImportConcern
  extend ActiveSupport::Concern

  include LoadRemoteXlsxConcern
  include ItemExcelParserConcern

  SKIP_ROW_OFFSET = 2
  SEMICOLON_REGEXP = /[;；]/
  PLACEHOLDER_IMAGE_NAME = "zhanweitu.jpg".freeze
  BASIC_SKU_FIELDS = %w[
    quantity price_in_yuan image position barcode strikethrough_price_in_yuan
    weight_in_gram height_in_cm width_in_cm length_in_cm on_sale gst_percent
    marketing_mode is_special is_private_kitchen shoppingunit discount_quantity discount_price_in_yuan
    properties no is_box_regulation
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
        store_id = row["store_id"]
        item_no = row["item_no"]
        sku_no = row["no"]

        break if store_id.blank? || item_no.blank? || sku_no.blank?

        item = MagicBean::Item.find_by(store_id: store_id, no: item_no)

        if item.nil?
          error_messages << "第#{idx}行：没有找到编号 #{item_no} 的商品"
          next
        end

        sku = MagicBean::StockKeepingUnit.find_or_initialize_by(no: sku_no, item_id: item.id, store_id: store_id)

        sku_params = process_sku_row(row, sku.new_record?)

        log_message = sku.generate_change_log(sku_params)

        sku.assign_attributes(sku_params)
        sku.import_skip_validation = sku_params[:barcode].blank?

        sku_errors = validate_sku(sku, sku_params, admin_user)
        if sku_errors.any?
          error_messages << "第#{idx}行：#{sku_errors.join('; ')}"
          next
        end

        if sku.save && log_message.present?
          admin_user.operation_records.create(operatable: sku.item, content: log_message, store_id: item.store_id, channel: :admin)
        end
      end

      error_messages
    end

    def process_sku_row(hash, is_new_record)
      row = ActiveSupport::HashWithIndifferentAccess.new(hash)

      if is_new_record && row[:properties].present?
        properties_array = row[:properties].split(SEMICOLON_REGEXP).map(&:strip)

        properties = properties_array.map do |property|
          property_values = property&.strip&.split(/[:：]/)

          next if property_values.blank?

          sku_property_str = property_values[0]&.strip
          sku_value_str = property_values[1]&.strip

          next if sku_property_str.blank? || sku_value_str.blank?

          sku_property = MagicBean::SkuProperty.find_or_create_by(text: sku_property_str)
          sku_value = sku_property.sku_values.find_or_create_by(text: sku_value_str)

          "#{sku_property.id}:#{sku_value.id}"
        end.join(MagicBean::StockKeepingUnit::PROPERTIES_SEPARATOR)

        row[:properties] = properties
      else
        # 不允许更新 sku 规格
        row[:properties] = nil
      end

      row[:marketing_mode] = get_marketing_mode_key(row[:marketing_mode])

      row[:on_sale] = get_boolean_value(row[:on_sale])

      row[:is_special] = get_boolean_value(row[:is_special])

      row[:is_private_kitchen] = get_boolean_value(row[:is_private_kitchen])

      row[:is_box_regulation] = get_boolean_value(row[:is_box_regulation])

      # 字段白名单，并且剔除 nil 元素
      row.slice(*BASIC_SKU_FIELDS).compact
    end

    def validate_sku(sku, sku_params, admin_user)
      error_messages = []

      if sku.price_in_cent_changed? && admin_user.can_not_force_update_sku_price? && sku.price_less_than_supplier_cost_multiple?(sku.price_in_cent)
        error_messages << "SKU（#{sku.no}）售价需不低于进货价的指定倍数"
      end

      if sku.in_time_limited_promotion? && sku_params[:quantity].present?
        error_messages << "SKU（#{sku.no}）处于限时优惠期，不可修改库存"
      end

      duplicated_properties = MagicBean::StockKeepingUnit.where(item_id: sku.item_id, properties: sku.properties).where.not(no: sku.no).exists?
      if duplicated_properties
        error_messages << "该产品已有此规格SKU"
      end

      if !sku.valid?
        error_messages += sku.errors.full_messages
      end

      error_messages
    end
  end
end
