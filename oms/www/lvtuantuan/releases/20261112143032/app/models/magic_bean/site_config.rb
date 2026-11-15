# frozen_string_literal: true
module MagicBean
  class SiteConfig < ApplicationRecord
    include PriceConvertConcern
    # scope

    # constants
    BASE_ATTRS = %w(all_category_icon mine_page_banner invite_page_banner overseas_student_icon)

    INTEGRAL_RULES_ATTRS = %w(sign_up_integral suggest_integral inviting_integral integral_received_from_one_yuan
      integral_deducted_from_one_yuan max_integral_in_one_order)

    INTEGRAL_SPECIAL_PERIOD_RULE_ATTRS = %w(
      integral_special_rule_name
      integral_special_rule_started_at
      integral_special_rule_ended_at
      integral_special_rule_received_from_one_yuan
      integral_special_rule_enabled
    )

    # [微信支付手续费百分比 银联信用卡支付手续费百分比 VM信用卡支付手续费百分比 是否开启信用卡支付 汇率上浮百分比 Omipay微信支付手续费百分比 Omipay支付宝支付手续费百分比 是否启用CommWeb 3DS身份验证
    # ApplePay手续费百分比 ApplePayNote CBAApplePay手续费百分比 CBAApplePayNote
    PAYMENT_SETTINGS = %w(wechat_service_percentage wechat_note unionpay_credit_card_service_percentage
                          unionpay_note vm_credit_card_service_percentage commweb_note credit_card_enable
                          exchange_rate_rise_percentage omipay_wechat_service_percentage omipay_wechat_note
                          omipay_alipay_service_percentage omipay_alipay_note supay_wechat_service_percentage
                          supay_wechat_note supay_alipay_service_percentage supay_alipay_note enable_commweb_3ds_auth
                          apple_pay_service_percentage apple_pay_note cba_apple_pay_service_percentage cba_apple_pay_note
                          cba_google_pay_service_percentage cba_google_pay_note)

    DELIVERY_TYPE_SETTINGS = %w(merchant_delivery_remark self_pick_remark express_remark)

    WATERMARK_ATTRIBUTES = %w(is_image watermark_image_name resize_p watermark_text transparency geography x_coordinate y_coordinate voffset size color rotate)

    VALUE_ADDED_SERVICE_SETTINGS = %w(deliver_to_door_enabled deliver_to_door_service_fee)

    enum config_type: { application: 1, sms: 2 }

    convert_price_to_yuan :sku_minimum_profit_in_cent

    # attr related macros

    # association macros
    belongs_to :store, optional: true
    has_many :operation_records, dependent: :destroy, as: :operatable

    # validation macros
    validates :sku_cost_minimum_factor, presence: true, numericality: { greater_than: 0 }
    validates :ae_sku_cost_minimum_factor, presence: true, numericality: { greater_than: 0 }
    validate :check_order_analyses_notify_emails_valid
    validate :check_integral_rules_valid
    validate :check_android_sms_notification_emails_valid
    validate :check_payment_callback_timeout_emails_valid
    validate :check_sku_price_exception_emails_valid
    validate :check_cutoff_time_valid
    validate :check_integral_special_period_rule_valid
    validate :coupon_templates_not_include_random_reduction
    validates :sku_minimum_profit_in_cent, allow_nil: true, numericality: { greater_than_or_equal_to: 4000, message: "必须大于或等于$40" }

    # callbacks
    after_save :save_address_limit_to_redis, if: :saved_change_to_merchant_delivery_orders_limit_every_day?
    after_commit :update_shopline_items, on: :update, if: :saved_change_to_shopline_price_rate?

    # other macros

    class << self
      def default_config
        MagicBean::SiteConfig.application.where(store_id: nil).first
      end

      def sms_config
        MagicBean::SiteConfig.sms.first
      end

      def default_store_config
        MagicBean::Store.default.first&.site_config
      end
    end

    BASE_ATTRS.each do |attr_name|
      define_method attr_name do
        @attr_name = base[attr_name]
      end
    end

    INTEGRAL_RULES_ATTRS.each do |attr_name|
      define_method attr_name do
        @attr_name = integral_rules[attr_name].to_i
      end
    end

    INTEGRAL_SPECIAL_PERIOD_RULE_ATTRS.each do |attr_name|
      define_method attr_name do
        @attr_name = integral_special_period_rule[attr_name]
      end
    end

    PAYMENT_SETTINGS.each do |attr_name|
      define_method attr_name do
        @attr_name =
          if attr_name.eql?("credit_card_enable") || attr_name.eql?("enable_commweb_3ds_auth")
            payment_settings[attr_name].in?(["true", true])
          elsif attr_name.include?("note")
            payment_settings[attr_name].to_s
          else
            payment_settings[attr_name].to_f
          end
      end
    end

    DELIVERY_TYPE_SETTINGS.each do |attr_name|
      define_method attr_name do
        @attr_name = delivery_type_settings[attr_name]
      end
    end

    WATERMARK_ATTRIBUTES.each do |attr_name|
      define_method attr_name do
        @attr_name =
          if attr_name.eql?("is_image")
            watermark_attributes[attr_name].in?(["true", true])
          else
            watermark_attributes[attr_name].to_s
          end
      end
    end

    # 增值服务目前只是增加开关，都是boolean
    VALUE_ADDED_SERVICE_SETTINGS.each do |attr_name|
      define_method attr_name do
        @attr_name = 
          if attr_name.eql?("deliver_to_door_enabled")
            value_added_service_settings[attr_name].in?(["true", true])
          elsif attr_name.eql?("deliver_to_door_service_fee")
            # 保留两位小数
            value_added_service_settings[attr_name].to_f.round(2)
          else
            value_added_service_settings[attr_name]
          end
      end
    end

    def store_invite_page_banner=(url)
      self.base["invite_page_banner"] = url
    end

    def store_invite_page_banner
      base["invite_page_banner"]
    end

    def title
      @title ||= "#{store.name}全站配置"
    end

    def encoded_image_name
      return if watermark_image_name.blank?
      split_str = Aliyun::CustomOss::DIR
      tmp_resize_p = resize_p.blank? ? 10 : resize_p
      image_name = split_str + watermark_image_name.split(split_str)[-1].split("?")[0] + "?x-oss-process=image/resize,p_#{tmp_resize_p}"# 根据上传到oss的根路径拆分
      Base64.strict_encode64(image_name)
    end

    def encoded_text
      return if watermark_text.blank?

      Base64.urlsafe_encode64(watermark_text)
    end

    def watermark_serialized
      if is_image && watermark_image_name.present?
        "watermark,image_#{encoded_image_name},t_#{transparency || 100},g_#{geography || "se"},x_#{x_coordinate || 10},y_#{y_coordinate || 10},voffset_#{voffset || 0}"
      elsif watermark_text.present?
        "watermark,size_#{size || 40},text_#{encoded_text},color_#{color || "000000"},rotate_#{rotate || 0}"
      end
    end

    def human_return_receiver_properties
      "#{ return_receiver_properties["full_receiver_address"] } #{ return_receiver_properties["receiver_name"] } #{ return_receiver_properties["tel_number"] }"
    end

    def has_items_video?
      web_item_list_video.dig("src").present?
    end

    def has_events_video?
      web_event_list_video.dig("src").present?
    end

    def check_order_analyses_notify_emails_valid
      order_analyses_notify_emails.each do |email|
        next if email =~ MagicBean::AdminUser::EMAIL_PATTERN
        errors.add(:base, "昨日订单情况通知邮件 格式不正确")
        break
      end
    end

    def check_android_sms_notification_emails_valid
      android_sms_notification_emails.each do |email|
        next if email =~ MagicBean::AdminUser::EMAIL_PATTERN
        errors.add(:base, "安卓短信发送失败通知邮箱 格式不正确")
        break
      end
    end

    def check_payment_callback_timeout_emails_valid
      payment_callback_timeout_emails.each do |email|
        next if email =~ MagicBean::AdminUser::EMAIL_PATTERN
        errors.add(:base, "支付回调超时通知邮箱 格式不正确")
        break
      end
    end

    def check_sku_price_exception_emails_valid
      sku_price_exception_emails.each do |email|
        next if email =~ MagicBean::AdminUser::EMAIL_PATTERN
        errors.add(:base, "商品售价低于进货价倍数通知邮箱 格式不正确")
        break
      end
    end

    def check_integral_rules_valid
      if INTEGRAL_RULES_ATTRS.select { |attr_name| integral_rules[attr_name].is_a?(Float) }.present?
        errors.add(:base, "积分规则中不能含有小数")
      end
    end

    def check_cutoff_time_valid
      errors.add(:base, "截止时间只能设置1~2个") if cutoff_time.size < 1 || cutoff_time.size > 2
    end

    def coupon_templates_not_include_random_reduction
      {
        newbie_coupon_templates: "新会员注册优惠券" ,
        invited_coupon_templates: "邀请新人优惠券" ,
        finish_order_coupon_templates: "被邀请人完成订单后邀请人获得券"
      }.each_pair do |key, val|
        if send(key).exists?(kind: :random_reduction)
          self.errors.add(:base, "#{val}不能关联随机满减券")
        end
      end
    end

    def check_customer_services_valid
      errors.add(:base, "至少设置一个客服") if customer_services.size < 1
    end

    def check_integral_special_period_rule_valid
      start_time = integral_special_period_rule["integral_special_rule_started_at"]
      end_time = integral_special_period_rule["integral_special_rule_ended_at"]

      count = [start_time, end_time].compact.count
      if count.odd?
        errors.add(:base, "积分规则时间不能只设置一个")
      end

      if count == 2 && start_time > end_time
        errors.add(:base, "积分规则开始时间不能晚于结束时间")
      end
    end

    def newbie_coupon_templates
      MagicBean::CouponTemplate.select(:id, :title, :kind).where(id: newbie_coupon_template_ids)
    end

    def web_newbie_coupon_templates
      MagicBean::CouponTemplate.select(:id, :title, :kind).where(id: web_newbie_coupon_template_ids)
    end

    def invited_coupon_templates
      MagicBean::CouponTemplate.select(:id, :title, :kind).where(id: invited_coupon_template_ids)
    end

    def web_invited_coupon_templates
      MagicBean::CouponTemplate.select(:id, :title, :kind).where(id: web_invited_coupon_template_ids)
    end

    def finish_order_coupon_templates
      MagicBean::CouponTemplate.select(:id, :title, :kind).where(id: finish_order_coupon_template_ids_to_inviter)
    end

    def web_finish_order_coupon_templates
      MagicBean::CouponTemplate.select(:id, :title, :kind).where(id: web_finish_order_coupon_template_ids_to_inviter)
    end

    def birthday_coupon_template
      MagicBean::CouponTemplate.select(:id, :title, :kind).find_by(id: birthday_coupon_template_id)
    end

    def web_birthday_coupon_template
      MagicBean::CouponTemplate.select(:id, :title, :kind).find_by(id: web_birthday_coupon_template_id)
    end

    def info_finished_coupon_template
      MagicBean::CouponTemplate.select(:id, :title, :kind).find_by(id: info_finished_coupon_template_id)
    end

    def web_info_finished_coupon_template
      MagicBean::CouponTemplate.select(:id, :title, :kind).find_by(id: web_info_finished_coupon_template_id)
    end

    def format_cutoff_time
      cutoff_time.map { |str| (eval str).transform_keys(&:to_sym) }.sort { |x, y| x[:time] <=> y[:time] }
    end

    def save_address_limit_to_redis
      Rails.cache.redis.set "store-#{store_id}-orders-limit-every-day", merchant_delivery_orders_limit_every_day
    end

    def new_user_custom_page
      page = MagicBean::CustomPage.find_by(id: new_user_custom_page_id)
      if page
        { id: page.id, name_with_store: page.name_with_store }
      end
    end

    def generate_log_message(new_attrs)
      log_message = []
      # TODO: 根据门店时区设置时间
      if integral_special_period_rule["integral_special_rule_started_at"] != new_attrs["integral_special_period_rule"]["integral_special_rule_started_at"]
        log_message << "积分特殊规则开始时间从 #{integral_special_period_rule['integral_special_rule_started_at'].in_time_zone rescue '空'} 改为 #{new_attrs['integral_special_period_rule']['integral_special_rule_started_at'].in_time_zone rescue '空'}"
      end

      if integral_special_period_rule["integral_special_rule_ended_at"] != new_attrs["integral_special_period_rule"]["integral_special_rule_ended_at"]
        log_message << "积分特殊规则结束时间从 #{integral_special_period_rule['integral_special_rule_ended_at'].in_time_zone rescue '空'} 改为 #{new_attrs['integral_special_period_rule']['integral_special_rule_ended_at'].in_time_zone rescue '空'}"
      end

      if integral_special_period_rule["integral_special_rule_received_from_one_yuan"] != new_attrs["integral_special_period_rule"]["integral_special_rule_received_from_one_yuan"]
        log_message << "特殊消费$1获得积分数从 #{integral_special_period_rule['integral_special_rule_received_from_one_yuan']} 改为 #{new_attrs['integral_special_period_rule']['integral_special_rule_received_from_one_yuan']}"
      end

      if integral_special_period_rule["integral_special_rule_enabled"] != new_attrs["integral_special_period_rule"]["integral_special_rule_enabled"]
        log_message << "积分特殊规则改为了 #{new_attrs['integral_special_period_rule']['integral_special_rule_enabled'] ? '启用' : '禁用'}"
      end

      log_message.join("，")
    end

    def update_shopline_items
      return unless store_id
      # shopline价格倍率发生变化时，同步更新该门店下所有shopline渠道的商品
      MagicBean::Item.online.shopline_channel.where(id: MagicBean::ThirdPartyItem.shopline.select(:item_id), store_id: store_id).each do |item|
        SyncItemToShoplineJob.perform_later(item.id)
      end
    end
  end
end
