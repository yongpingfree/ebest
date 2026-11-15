# frozen_string_literal: true

module ItemImportConcern
  extend ActiveSupport::Concern

  include LoadRemoteXlsxConcern
  include ItemExcelParserConcern

  SKIP_ROW_OFFSET = 2
  SEMICOLON_REGEXP = /[;；]/
  PLACEHOLDER_IMAGE_NAME = "zhanweitu.jpg".freeze
  BASIC_ITEM_FIELDS = %w[
    store_id no leader title_zh_cn title_en short_title category_id storage_method
    minor_category_id brand_id description_zh_cn shared_description_zh_cn
    allergen sales_count_offset channels tag_list buy_quota production_place
    buy_quota_days listing_type start_selling_at is_presell presell_end_at
    presell_dispatch_on latest_presell_dispatch_on coupon_enabled delivery_type
    default_freight_template_ids cover share_cover main_images detail_images
    qa_and_guarantee_id freight_type is_virtual position serving_per_package
    serving_size description_en shared_description_en ingredient free_shipping
    gift_card_enabled show_expiration_date days_ahead_to_show_expiration expiration_reminder_before_n_days
    web_category_id minor_web_category_id not_eligible_for_free_gift is_seasonal is_fresh_daily
    delivery_weekdays cutoff_times_attributes
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
        cutoff_time_at = row["cutoff_time_at"]&.strip
        cutoff_time_weekdays = row["cutoff_time_weekdays"]&.strip
        cutoff_time_deliver_after_n_days = row["cutoff_time_deliver_after_n_days"].to_s&.strip

        break if store_id.blank? && item_no.blank?

        if store_id.blank?
          error_messages << "第#{idx}行：门店ID不能为空"
          next
        end

        clear_cutoff_time = cutoff_time_at&.include?("清空") || cutoff_time_weekdays&.include?("清空") || cutoff_time_deliver_after_n_days&.include?("清空")
        
        # cutoff_time_at、cutoff_time_weekdays、cutoff_time_deliver_after_n_days必须同时存在或同时不存在, 且值不为 清空
        not_blank_count = [cutoff_time_at, cutoff_time_weekdays, cutoff_time_deliver_after_n_days].count(&:present?)

        if not_blank_count > 0 && not_blank_count < 3 && !clear_cutoff_time
          error_messages << "第#{idx}行：截止时间、截止星期数和截单后N天发货 必须同时存在"
          next
        end

        item = if item_no.present?
                 MagicBean::Item.find_or_initialize_by(store_id: store_id, no: item_no)
               else
                 MagicBean::Item.new(store_id: store_id)
               end

        item_params = process_item_row(row, item.new_record?, clear_cutoff_time)

        if item_params[:cutoff_times_attributes].present? || clear_cutoff_time
          item_params[:cutoff_times_attributes] ||= []

          # 将原有的cutoff_times删除
          item.cutoff_times.each do |cutoff_time|
            item_params[:cutoff_times_attributes] << { id: cutoff_time.id, _destroy: true }
          end
        end

        log_message = item.generate_change_log(item_params)

        item.assign_attributes(item_params)
        product_params = get_product_params(item, item_params)
        item.product_attributes = product_params if product_params.present?

        item_errors = validate_item(item, item_params, admin_user)

        if item_errors.any?
          error_messages << "第#{idx}行：#{item_errors.join('; ')}"
          next
        end

        begin
          if item.save && log_message.present?
            admin_user.operation_records.create(operatable: item, content: log_message, store_id: item.store_id, channel: :admin)
          end
        rescue ActiveRecord::StatementInvalid
          error_messages << "第#{idx}行：无法处理的单元格数据，请联系技术人员检查"
        end
      end

      error_messages
    end

    # NOTE:
    #   如果是新增记录，没填值的 key 需要设置默认值
    #   如果是更新记录，没填值的 key 需要抛弃
    def process_item_row(hash, is_new_record, clear_cutoff_time)
      row = ActiveSupport::HashWithIndifferentAccess.new(hash)
      row.each {|key, value| row[key] = value.present? ? value.to_s.strip : nil }

      # 平台限制(APP/小程序/Web网站，默认为三个平台均可用)
      if is_new_record && row[:channels].blank?
        row[:channels] = MagicBean::Item::CHANNEL_ARRAY
      else
        row[:channels] = get_channels(row[:channels]).presence
      end

      # 标签（分号隔开)
      row[:tag_list] = row[:tag_list]&.split(SEMICOLON_REGEXP)

      # 将截单时间的中文冒号转换为英文冒号
      if !clear_cutoff_time
        cutoff_time_at = row.delete(:cutoff_time_at)&.strip&.split(SEMICOLON_REGEXP)&.map {|time| time.gsub("：", ":")}
        cutoff_time_weekdays = row.delete(:cutoff_time_weekdays)&.strip&.split(SEMICOLON_REGEXP)&.map {|weekday| get_weekday_value(weekday)}
        cutoff_time_deliver_after_n_days = row.delete(:cutoff_time_deliver_after_n_days)
        row[:delivery_weekdays] = row[:delivery_weekdays]&.strip&.split(SEMICOLON_REGEXP)&.map {|weekday| get_weekday_value(weekday)}
  
        if cutoff_time_at.present? && cutoff_time_weekdays.present?
          row[:cutoff_times_attributes] = [
            {
              time_at: cutoff_time_at,
              weekdays: cutoff_time_weekdays,
              deliver_after_n_days: cutoff_time_deliver_after_n_days
            }
          ]
        end
      end

      # 上架类型(立即上架售卖/自定义上架时间/暂不售卖，默认为暂不售卖)
      if is_new_record && row[:listing_type].blank?
        row[:listing_type] = :pending
      else
        row[:listing_type] = get_listing_type(row[:listing_type])
      end

      # 是否预售商品
      if is_new_record && row[:is_presell].blank?
        row[:is_presell] = false
      else
        row[:is_presell] = get_boolean_value(row[:is_presell])
      end

       # 是否时令商品
      if is_new_record && row[:is_seasonal].blank?
        row[:is_seasonal] = false
      else
        row[:is_seasonal] = get_boolean_value(row[:is_seasonal])
      end

       # 是否每日鲜商品
      if is_new_record && row[:is_fresh_daily].blank?
        row[:is_fresh_daily] = false
      else
        row[:is_fresh_daily] = get_boolean_value(row[:is_fresh_daily])
      end

      # 是否可用优惠券
      if is_new_record && row[:coupon_enabled].blank?
        row[:coupon_enabled] = true
      else
        row[:coupon_enabled] = get_boolean_value(row[:coupon_enabled])
      end

      # 是否可用礼品券
      if is_new_record && row[:gift_card_enabled].blank?
        row[:gift_card_enabled] = true
      else
        row[:gift_card_enabled] = get_boolean_value(row[:gift_card_enabled])
      end

      # 是否虚拟商品
      if is_new_record && row[:is_virtual].blank?
        row[:is_virtual] = false
      else
        row[:is_virtual] = get_boolean_value(row[:is_virtual])
      end

      # 是否不参与满赠
      if is_new_record && row[:not_eligible_for_free_gift].blank?
        row[:not_eligible_for_free_gift] = false
      else
        row[:not_eligible_for_free_gift] = get_boolean_value(row[:not_eligible_for_free_gift])
      end

      # 配送方式
      if row[:delivery_type].present?
        row[:delivery_type] = row[:delivery_type].split(SEMICOLON_REGEXP).map { |val| get_delivery_type(val) }.compact
      end

      # 运费模版ID
      if row[:default_freight_template_ids].present?
        freight_template_ids = row[:default_freight_template_ids].to_s.split(SEMICOLON_REGEXP).map(&:strip).compact
        row[:default_freight_template_ids] = freight_template_ids.select { |id| MagicBean::DefaultFreightTemplate.exists?(id: id, store_id: row[:store_id]) }
        row[:freight_type] = :freight_template
      end

      # 是否参与包邮计算
      if is_new_record && row[:free_shipping].blank?
        row[:free_shipping] = true
      else
        row[:free_shipping] = get_boolean_value(row[:free_shipping])
      end

      # 存储方式（常温、冷藏、冷冻、其他、/）
      if is_new_record && row[:storage_method].blank?
        row[:storage_method] = :room_temp_storage
      else
        row[:storage_method] = get_storage_method_key(row[:storage_method])
      end

      # 是否显示过期日期
      if is_new_record && row[:show_expiration_date].blank?
        row[:show_expiration_date] = false
      else
        row[:show_expiration_date] = get_boolean_value(row[:show_expiration_date])
      end

      # 单图片字段
      [:cover, :share_cover].each do |image_key|
        if row[image_key].blank?
          row[image_key] = get_image_url(PLACEHOLDER_IMAGE_NAME) if is_new_record
        else
          row[image_key] = get_image_url(row[image_key])
        end
      end

      # 图片数组字段
      [:main_images, :detail_images].each do |image_key|
        if row[image_key].blank?
          row[image_key] = [get_image_url(PLACEHOLDER_IMAGE_NAME)] if is_new_record
        else
          row[image_key] = row[image_key].to_s.split(SEMICOLON_REGEXP).map { |filename| get_image_url(filename) }
        end
      end

      # 字段白名单，并且剔除 nil 元素
      row = row.slice(*BASIC_ITEM_FIELDS).compact
      row["minor_category_id"] = nil if row["minor_category_id"] == -1
      row["minor_web_category_id"] = nil if row["minor_web_category_id"] == -1
      row
    end

    def get_product_params(item, item_params)
      product = item.product

      if product.blank? || product.store_id == item.store_id
        product_params = {
          id: product&.id,
          title: item_params[:title_zh_cn],
          sub_title: item_params[:title_en],
          short_title: item_params[:short_title],
          description: item_params[:description_zh_cn],
          shared_description: item_params[:shared_description_zh_cn],
          cover: item_params[:cover],
          share_cover: item_params[:share_cover],
          category_id: item_params[:category_id],
          qa_and_guarantee_id: item_params[:qa_and_guarantee_id],
          brand_id: item_params[:brand_id],
          store_id: item_params[:store_id],
          detail_images: item_params[:detail_images],
          main_images: item_params[:main_images],
          sales_count_offset: item_params[:sales_count_offset]
        }

        product_params.compact
      else
        {}
      end
    end

    def validate_item(item, item_params, admin_user)
      error_messages = []

      # 不能修改已保存商品的属性
      if !item.new_record?
        error_messages << "不可修改产品 store_id" if item.store_id_changed?
        error_messages << "不可修改是否虚拟商品" if item.is_virtual_changed?
      end

      # 检查运费模版是否已存在
      if item_params[:default_freight_template_ids].present?
        if item.default_freight_templates.size != item.delivery_type.size
          error_messages << "请检查配送方式和运费模板id"
        end
      end

      # 检查分类是否存在
      error_messages << "找不到主产品二级分类" if item_params[:category_id].present? && item.category.blank?
      error_messages << "找不到次产品二级分类" if item_params[:minor_category_id].present? && item.minor_category.blank?
      error_messages << "找不到网站主产品二级分类" if item_params[:web_category_id].present? && item.web_category.blank?
      error_messages << "找不到网站次产品二级分类" if item_params[:minor_web_category_id].present? && item.minor_web_category.blank?

      # 检查品牌是否存在
      error_messages << "找不到品牌" if item_params[:brand_id].present? && item.brand.blank?

      # 商品暂不售卖时跳过校验
      if item.pending?
        item.import_skip_validation = true
        item.product.import_skip_validation = true
      else
        item.import_skip_validation = false
        item.product.import_skip_validation = false
      end

      if !item.valid?
        error_messages += item.errors.full_messages
      end

      error_messages
    end

    def get_listing_type(value_cn)
      str = value_cn.to_s.strip

      case str
      when "立即上架售卖"
        :online
      when "自定义上架时间"
        :advance_on
      when "暂不售卖"
        :pending
      else
        nil
      end
    end
  end
end
