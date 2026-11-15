# frozen_string_literal: true

module BeansApp::API::Entities
  class PreviewGiftActivity < ::CommonEntities::Model
    expose :custom_rules, as: :rules

    def custom_rules
      object.human_rules(options[:delivery_type], options[:order_item_amount_in_yuan])
    end
  end

  class PreviewOrder < SimpleOrder
    # 参与满赠活动的商品总金额
    expose :eligible_for_free_gift_amount_in_cent
    expose :eligible_for_free_gift_amount_in_yuan
    expose :strikethrough_amount_in_cent
    expose :strikethrough_amount_in_yuan
    expose :buyer_message
    expose :items_available_delivery_types
    expose :available_delivery_time
    expose :available_delivery_dates
    expose :parent_orders_delivery_dates
    expose :same_day_delivery_time_id
    expose :same_day_delivery_time_period_id
    expose :address, using: Address do |_, options|
      options[:address]
    end
    expose :coupon, using: Coupon do |_, options|
      options[:coupon]
    end
    expose :gift_card_coupon, using: GiftCardCoupon do |_, options|
      options[:gift_card_coupon]
    end
    expose :errors do |order|
      order.errors.values.flatten.uniq.join("，")
    end
    expose :max_cost_integral
    expose :max_cost_integral_amount_in_yuan
    expose :earliest_delivery_start_at
    expose :earliest_delivery_end_at
    expose :earliest_delivery_wday
    expose :earliest_delivery_date
    expose :earliest_delivery_time
    expose :delivery_text
    expose :custom_delivery_date, as: :delivery_date
    expose :custom_prefer_time, as: :prefer_time
    expose :gst_amount_in_yuan, documentation: { desc: "GST税金" }
    expose :gift_activity do |_, _|
      if object.virtual_delivery?
        nil
      else
        # 过滤掉不参与满赠商品金额，再减去礼品卡的金额
        PreviewGiftActivity.represent(object.gift_activity, order_item_amount_in_yuan: object.eligible_for_free_gift_amount_in_yuan_num, delivery_type: object.delivery_type)
      end
    end
    expose :delivery_type_settings do |_, _|
      object.send(:current_store_site_config)&.delivery_type_settings
    end

    expose :value_added_service_settings do |_, _|
      object.send(:current_store_site_config)&.value_added_service_settings
    end

    expose :last_order_email do |order|
      order.user.virtual_orders.order(:id).last&.receiver_email if order.type == "MagicBean::VirtualOrder"
    end

    expose :order_deliver_to_door_text do |order|
      order.admin_multi_lang_config(I18n.locale.to_s)&.order_deliver_to_door_text
    end

    expose :child_order_dates_notice do |order|
      order.admin_multi_lang_config(I18n.locale.to_s)&.child_order_dates_notice
    end

    def earliest_delivery_start_at
      return nil if object.virtual_delivery? || object.type == "MagicBean::SameDayDeliveryOrder" || earliest_time.blank?
      "#{earliest_time[:date]} #{earliest_time[:time].split("-").first}".in_time_zone(object.order_store_time_zone)
    end

    def earliest_delivery_end_at
      return nil if object.virtual_delivery? || object.type == "MagicBean::SameDayDeliveryOrder" || earliest_time.blank?
      "#{earliest_time[:date]} #{earliest_time[:time].split("-").last}".in_time_zone(object.order_store_time_zone)
    end

    def earliest_delivery_wday
      return nil if object.virtual_delivery? || object.type == "MagicBean::SameDayDeliveryOrder" || earliest_time.blank?
      earliest_time[:wday]
    end

    def earliest_delivery_date
      return nil if object.virtual_delivery? || object.type == "MagicBean::SameDayDeliveryOrder" || earliest_time.blank?
      earliest_time[:date]
    end

    def earliest_delivery_time
      return nil if object.virtual_delivery? || object.type == "MagicBean::SameDayDeliveryOrder" || earliest_time.blank?
      earliest_time[:time]
    end

    def earliest_time
      @earliest_time ||= object.send(:calculate_earliest_delivery_time).first
    end

    def delivery_text
      return "" if object.virtual_delivery? || object.type == "MagicBean::SameDayDeliveryOrder" || earliest_time.blank?
      date_alias = if Date.current == earliest_time[:date]
                     "#{I18n.t("grape.delivery.today")}（#{earliest_time[:date].strftime(date_strftime)}）"
                   elsif Date.tomorrow == earliest_time[:date]
                     "#{I18n.t("grape.delivery.tomorrow")}（#{earliest_time[:date].strftime(date_strftime)}）"
                   else
                    earliest_time[:date].strftime(date_strftime)
                   end

      time = earliest_time&.dig(:selected_cot, :time)
      time_text = english_locale? ? time_en_format(time) : time
      delivery_time_text = english_locale? ? earliest_time[:date].strftime(date_strftime) : date_alias

      if object.express?
        i18n_name = object.ae_drop_shipper? ? "ae_choice_delivery_text" : "express_delivery_text"
        I18n.t("grape.delivery.#{i18n_name}", time: time_text, delivery_time: delivery_time_text)
      else
        I18n.t("grape.delivery.delivery_reach_text", time: time_text, delivery_time: delivery_time_text)
      end
    end

    def available_delivery_dates
      return [] if object.virtual_delivery?
      object.send(:available_delivery_dates)
    end

    def custom_delivery_date
      return nil if object.virtual_delivery?
      if (object.merchant_delivery? || object.self_pick?) && available_delivery_dates.blank?
        nil
      else
        object.delivery_date
      end
    end

    def custom_prefer_time
      return nil if object.virtual_delivery?
      (object.merchant_delivery? || object.self_pick?) && available_delivery_dates.blank? ? nil : object.prefer_time
    end
  end
end
