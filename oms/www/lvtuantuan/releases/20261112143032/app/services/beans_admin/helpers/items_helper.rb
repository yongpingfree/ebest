# frozen_string_literal: true

module BeansAdmin::Helpers
  module ItemsHelper

    ITEM_FIELDS = %w[
      store_id item_no leader title_zh_cn title_en short_title category_id minor_category_id brand_id description_zh_cn
      shared_description_zh_cn qa_and_guarantee_id sales_count_offset channels tag_list buy_quota buy_quota_days is_presell presell_end_at presell_dispatch_on
      latest_presell_dispatch_on is_virtual coupon_enabled delivery_type default_freight_template_ids storage_method properties_arr sku_no price_in_yuan strikethrough_price_in_yuan
      discount_quantity discount_price_in_yuan ae_price_in_yuan quantity barcode gst_percent marketing_mode shoppingunit is_special is_private_kitchen length_in_cm
      width_in_cm height_in_cm weight_in_gram cover share_cover main_images detail_images sku_image is_seasonal is_fresh_daily
    ]

    def get_channels(value_cn)
      arr = value_cn.to_s.split(/[;；]/).map(&:strip)

      arr.map do |str|
        case str
        when "APP"
          "app"
        when "小程序"
          "mini_program"
        when "Web网站"
          "web"
        when "shopline", "Shopline"
          "shopline"
        when "aliexpress", "AE", "Aliexpress"
          "aliexpress"
        else
          nil
        end
      end.compact.uniq
    end

    def get_delivery_type(name)
      case name
      when /[商家](配送|派送)/
        "merchant_delivery"
      when "自提"
        "self_pick"
      when "快递", "邮寄"
        "express"
      end
    end

    def get_storage_method(name_cn)
      str = name_cn.to_s.strip

      case str
      when "常温"
        :room_temp_storage
      when "冷藏"
        :refrigerated_storage
      when "冷冻"
        :frozen_storage
      when "其他"
        :other_storage
      when "/"
        :blank_storage
      else
        nil
      end
    end

    def get_marketing_mode(name_cn)
      str = name_cn.to_s.strip

      case str
      when "寄售"
        "consign_for_sale"
      when "平台"
        "platform"
      when "自营"
       "self_support"
      else
        nil
      end
    end

    def get_image_url(name)
      return if name.blank?
      "https://#{Rails.application.credentials.dig(Rails.env.to_sym, :aws)[:cdn_host]}/items/#{name}"
    end

    def set_import_params(row, import_admin_user = nil)
      # 异步导入时没有 current_admin_user
      admin_user = respond_to?(:current_admin_user) ? current_admin_user : import_admin_user

      error_message, log_message = [], []

      row.each {|key, value| row[key] = value.present? ? value.to_s.strip : nil }

      ITEM_FIELDS.each do |key|
        value = row[key]

        value = case key
        when "channels", "storage_method", "marketing_mode"
          send("get_#{key}", value)
        when "tag_list", "default_freight_template_ids", "properties_arr"
          value&.split(/[;；]/) || []
        when "is_presell", "is_virtual", "coupon_enabled", "is_special", "is_private_kitchen", "is_seasonal", "is_fresh_daily"
          value && value == "是"
        when "presell_end_at"
          row["is_presell"] == "是" ? value&.in_time_zone(ApplicationRecord::TIME_ZONE) : nil
        when "presell_dispatch_on", "latest_presell_dispatch_on"
          row["is_presell"] == "是" ? value : nil
        when "delivery_type"
           (value&.split(/[;；]/) || []).map { |type| get_delivery_type(type) }.compact
        when "gst_percent"
          value.presence
        when "cover", "share_cover", "sku_image"
          get_image_url(value)
        when "main_images", "detail_images"
          (value&.split(/[;；]/) || []).map { |image_name| get_image_url(image_name) }
        else
          value
        end

        instance_variable_set("@#{key}", value)
      end

      # 判断分类id是否为二级分类id
      error_message << "主产品二级分类id不可使用一级分类id" if @category_id.present? && MagicBean::Category.top.exists?(id: @category_id)
      error_message << "次产品二级分类id不可使用一级分类id" if @minor_category_id.present? && MagicBean::Category.top.exists?(id: @minor_category_id)

      old_item = MagicBean::Item.find_by no: @item_no

      # 导入编号找不到产品，且导入编号填写了，提示错误
      error_message << "新增产品请不要填写导入编号" if old_item.blank? && @item_no.present?
      error_message << "不可修改产品store_id" if old_item && @store_id.present? && old_item.store_id != @store_id.to_i
      error_message << "不可修改是否虚拟产品" if old_item && !@is_virtual.nil? && old_item.is_virtual != @is_virtual
      error_message << "请检查运费模板id" if @default_freight_template_ids.present? && ((MagicBean::DefaultFreightTemplate.where(id: @default_freight_template_ids).map { |template| template.id.to_s } - @default_freight_template_ids) != [])

      @is_virtual = false if @is_virtual.nil? && old_item.blank?
      @coupon_enabled = true if @coupon_enabled.nil? && old_item.blank?
      @marketing_mode = "self_support" if @marketing_mode.nil? && old_item.blank?
      new_is_presell = (row["is_presell"].present? || old_item.blank?) ? @is_presell : old_item&.is_presell
      new_title = @title_zh_cn.presence || old_item&.title_zh_cn
      new_leader = @leader.presence || old_item&.leader || "其他"
      storage_method_key = @storage_method.presence || old_item&.storage_method || :room_temp_storage

      if old_item
        log_message << "导入修改产品标题从 #{old_item.title} 改为 #{new_title}" if new_title != old_item.title

        if new_is_presell != old_item.is_presell
          presell_message = "导入修改产品预售状态从 #{old_item.is_presell ? "是" : "否"} 更改为 #{new_is_presell ? "是" : "否"}"
          presell_message += ", 商品预售结束时间为 #{@presell_end_at.in_time_zone(ApplicationRecord::TIME_ZONE)}, 预售可派送最早日期为 #{@presell_dispatch_on}, 预售可派送最晚日期为 #{@latest_presell_dispatch_on}" if new_is_presell && @presell_end_at.present?
          log_message << presell_message
        elsif new_is_presell
          presell_messages = []
          presell_messages << "商品预售结束时间从 #{old_item.presell_end_at} 更改为 #{@presell_end_at.in_time_zone(ApplicationRecord::TIME_ZONE)}" if @presell_end_at.present? && @presell_end_at != old_item.presell_end_at
          presell_messages << "预售可派送最早日期从 #{old_item.presell_dispatch_on} 更改为 #{@presell_dispatch_on}" if @presell_dispatch_on.present? && @presell_dispatch_on.to_s != old_item.presell_dispatch_on.to_s
          presell_messages << "预售可派送最晚日期从 #{old_item.latest_presell_dispatch_on} 更改为 #{@latest_presell_dispatch_on}" if @latest_presell_dispatch_on.present? && @latest_presell_dispatch_on.to_s != old_item.latest_presell_dispatch_on.to_s
          log_message << presell_messages.join(", ") if presell_messages.present?
        end
      end

      sku = old_item ? old_item.stock_keeping_units.find_by(no: @sku_no) : nil

      @is_special = false if @is_special.nil? && sku.blank?
      new_is_special = @is_special.nil? ? sku&.is_special : @is_special

      @is_private_kitchen = false if @is_private_kitchen.nil? && sku.blank?
      new_is_private_kitchen = @is_private_kitchen.nil? ? sku&.is_private_kitchen : @is_private_kitchen

      product = old_item&.product
      # 需要校验sku规格值是否跟商品已有规格值有冲突
      if old_item
        old_item_properties = old_item.stock_keeping_units.first.properties.split(";").map do |old_property|
          MagicBean::SkuProperty.find(old_property.split(",").first).text
        end
      end

      properties = (@properties_arr || []).map.with_index do |property, index|
        property_values = property&.strip&.split(/[:：]/)
        next if property_values.blank?
        sku_property_str = property_values[0]&.strip
        sku_value_str = property_values[1]&.strip
        if sku_property_str.blank? || sku_value_str.blank?
          error_message << "产品规格 #{sku_property_str}:#{sku_value_str} 有误"
          next
        end

        if old_item && sku_property_str != old_item_properties[index]
          error_message << "产品规格 #{sku_property_str}:#{sku_value_str} 无法找到匹配的规格名"
          next
        end

        sku_property = MagicBean::SkuProperty.find_or_create_by(text: sku_property_str)
        sku_value = sku_property.sku_values.find_or_create_by(text: sku_value_str)
        "#{sku_property.id}:#{sku_value.id}"
      end.join(";")

      brand = MagicBean::Brand.find_by id: @brand_id

      error_message << "该产品已有此规格SKU" if old_item.present? && properties.present? && old_item.stock_keeping_units.ransack(properties_cont: properties).result.where.not(no: @sku_no).exists?
      error_message << "新增SKU规格必填" if sku.blank? && properties.blank?

      new_price_in_yuan = @price_in_yuan.presence || sku&.price_in_yuan
      new_ae_price_in_yuan = @ae_price_in_yuan.presence || sku&.ae_price_in_yuan
      # 传0过来就清空discount_price、discount_quantity
      new_discount_price_in_yuan = if @discount_price_in_yuan.present?
                                     @discount_price_in_yuan.to_i.zero? ? nil : @discount_price_in_yuan
                                   else
                                     sku&.discount_price_in_yuan
                                   end
      new_discount_quantity = if @discount_quantity.present?
                                @discount_quantity.to_i.zero? ? nil : @discount_quantity
                              else
                                sku&.discount_quantity
                              end
      new_quantity = @quantity.presence || sku&.quantity
      new_barcode = @barcode.presence || sku&.barcode
      new_marketing_mode = @marketing_mode.presence || sku&.marketing_mode

      if sku.blank?
        log_message << "导入新增SKU, 货号为：#{@sku_no}, 数量为：#{@quantity}, 价格为：#{@price_in_yuan}, 折扣价为：#{@discount_price_in_yuan || "空"}, 购买数量大于等于 为：#{@discount_quantity || "空"}"
      else
        new_price_in_cent = new_price_in_yuan.present? ? (new_price_in_yuan.to_f * 100).round : nil
        price_in_cent_changed = new_price_in_cent != sku&.price_in_cent

        new_ae_price_in_cent = new_ae_price_in_yuan.present? ? (new_ae_price_in_yuan.to_f * 100).round : nil
        ae_price_in_cent_changed = new_ae_price_in_cent != sku&.ae_price_in_cent

        new_discount_price_in_cent = new_discount_price_in_yuan.present? ? (new_discount_price_in_yuan.to_f * 100).round : nil

        if price_in_cent_changed && admin_user.can_not_force_update_sku_price? && sku.price_less_than_supplier_cost_multiple?(new_price_in_cent)
          error_message << "SKU（#{sku.no}）售价需不低于进货价的指定倍数"
        end

        log_message << "导入修改SKU（#{@sku_no}）价格: 从 #{sku.price_in_yuan} 改为 #{new_price_in_yuan}" if price_in_cent_changed
        log_message << "导入修改SKU（#{@sku_no}）AE价格: 从 #{sku.ae_price_in_yuan} 改为 #{new_ae_price_in_yuan}" if ae_price_in_cent_changed
        log_message << "导入修改SKU（#{@sku_no}）折扣价格: 从 #{sku.discount_price_in_yuan || "空"} 改为 #{new_discount_price_in_yuan.presence || "空"}" if new_discount_price_in_cent.to_i != sku.discount_price_in_cent.to_i
        if new_quantity.to_i != sku.quantity
          log_message << "导入修改SKU（#{@sku_no}）数量: 从 #{sku.quantity} 改为 #{new_quantity}"
          error_message << "商品 #{@sku_no} 处于限时优惠期，不可修改库存" if sku.in_time_limited_promotion?
        end
        log_message << "导入修改SKU（#{@sku_no}）折扣数量: 从 #{sku.discount_quantity || "空"} 改为 #{new_discount_quantity.presence || "空"}" if new_discount_quantity.to_i != sku.discount_quantity.to_i
        log_message << "导入修改SKU（#{@sku_no}）barcode: 从 #{sku.barcode.presence || "空"} 改为 #{new_barcode.presence || "空"}" if new_barcode.to_s != sku.barcode.to_s
        log_message << "导入修改SKU（#{@sku_no}）是否特品: 从 #{sku.is_special ? "是" : "否"} 改为 #{new_is_special ? "是" : "否"}" if new_is_special != sku.is_special
        log_message << "导入修改SKU（#{@sku_no}）是否私厨: 从 #{sku.is_private_kitchen ? "是" : "否"} 改为 #{new_is_private_kitchen ? "是" : "否"}" if new_is_private_kitchen != sku.is_private_kitchen
        log_message << "导入修改SKU（#{@sku_no}）营销模式: 从 #{I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{sku.marketing_mode}")} 改为 #{I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{new_marketing_mode}")
        }" if new_marketing_mode != sku.marketing_mode
      end

      others_sku_attributes = (old_item&.stock_keeping_units&.where&.not(id: sku&.id) || []).map do |other_sku|
        {
          id: other_sku&.id,
          import_skip_validation: other_sku.barcode.blank?,
        }
      end

      item_attributes = {
        leader: new_leader,
        title_zh_cn: new_title,
        title_en: @title_en.presence || old_item&.title_en,
        short_title: @short_title.presence || old_item&.short_title,
        description_zh_cn: @description_zh_cn.presence || old_item&.description,
        shared_description_zh_cn: @shared_description_zh_cn.presence || old_item&.shared_description,
        cover: @cover.presence || old_item&.cover,
        share_cover: @share_cover.presence || old_item&.share_cover,
        category_id: @category_id.presence || old_item&.category_id,
        minor_category_id: @minor_category_id.presence || old_item&.minor_category_id,
        qa_and_guarantee_id: @qa_and_guarantee_id.presence || old_item&.qa_and_guarantee_id,
        brand_id: brand&.id || old_item&.brand_id,
        store_id: old_item&.store_id || @store_id.presence,
        sales_count_offset: @sales_count_offset.presence || old_item&.sales_count_offset,
        channels: @channels.presence || old_item&.channels.presence || MagicBean::Item::CHANNEL_ARRAY,
        buy_quota: @buy_quota.presence || old_item&.buy_quota || 0,
        buy_quota_days: @buy_quota_days.presence || old_item&.buy_quota_days || 0,
        is_presell: new_is_presell,
        presell_end_at: @presell_end_at.presence || old_item&.presell_end_at,
        presell_dispatch_on: @presell_dispatch_on.presence || old_item&.presell_dispatch_on,
        latest_presell_dispatch_on: @latest_presell_dispatch_on.presence || old_item&.latest_presell_dispatch_on,
        is_virtual: @is_virtual.nil? ? old_item&.is_virtual : @is_virtual,
        is_seasonal: @is_seasonal,
        is_fresh_daily: @is_fresh_daily,
        coupon_enabled: @coupon_enabled.nil? ? old_item&.coupon_enabled : @coupon_enabled,
        item_type: old_item&.item_type || "normal",
        listing_type: old_item&.listing_type || "pending",
        no: @item_no,
        freight_type: old_item&.freight_type || "freight_template",
        delivery_type: @delivery_type.presence || old_item&.delivery_type || [],
        default_freight_template_ids: @default_freight_template_ids.presence || old_item&.default_freight_template_ids,
        storage_method: storage_method_key,
        main_images: @main_images.presence || old_item&.main_images,
        detail_images: @detail_images.presence || old_item&.detail_images,
        import_skip_validation: true,
        stock_keeping_units_attributes: [
          {
            id: sku&.id,
            no: @sku_no,
            properties: properties.presence || sku&.properties,
            price_in_yuan: new_price_in_yuan,
            strikethrough_price_in_yuan: @strikethrough_price_in_yuan.presence || sku&.strikethrough_price_in_yuan,
            ae_price_in_yuan: new_ae_price_in_yuan,
            quantity: new_quantity,
            gst_percent: @gst_percent || sku&.gst_percent,
            marketing_mode: new_marketing_mode,
            shoppingunit: @shoppingunit.presence || sku&.shoppingunit,
            image: @sku_image.presence || sku&.image,
            barcode: new_barcode,
            weight_in_gram: @weight_in_gram.presence || sku&.weight_in_gram || 0,
            length_in_cm: @length_in_cm.presence || sku&.length_in_cm || 0,
            width_in_cm: @width_in_cm.presence || sku&.width_in_cm || 0,
            height_in_cm: @height_in_cm.presence || sku&.height_in_cm || 0,
            on_sale: sku.present? ? sku.on_sale : true,
            import_skip_validation: @barcode.blank?,
            is_special: new_is_special,
            is_private_kitchen: new_is_private_kitchen,
            discount_quantity: new_discount_quantity,
            discount_price_in_yuan: new_discount_price_in_yuan
          }
        ] + others_sku_attributes,
        tag_list: @tag_list.presence || old_item&.tag_list
      }

      if product.blank? || product.store_id == old_item.store_id
        item_attributes[:product_attributes] = {
          id: product&.id,
          title: new_title,
          sub_title: @title_en.presence || product&.sub_title,
          short_title: @short_title.presence || product&.short_title,
          description: @description_zh_cn.presence || product&.description,
          shared_description: @shared_description_zh_cn.presence || product&.shared_description,
          cover: @cover.presence || product&.cover,
          share_cover: @share_cover.presence || product&.share_cover,
          category_id: @category_id.presence || product&.category_id,
          qa_and_guarantee_id: @qa_and_guarantee_id.presence || product&.qa_and_guarantee_id,
          brand_id: brand&.id || product&.brand_id,
          store_id: product&.store_id || @store_id.presence,
          detail_images: @detail_images.presence || product&.detail_images,
          main_images: @main_images.presence || product&.main_images,
          sales_count_offset: @sales_count_offset.presence || product&.sales_count_offset,
          import_skip_validation: true
        }
      end

      [item_attributes, old_item, error_message, log_message]
    end
  end
end
