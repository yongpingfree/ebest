# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SiteConfig < ::CommonEntities::Model
    expose :custom_time_zone
    expose :base
    expose :return_receiver_properties
    expose :customer_service_name
    expose :integral_rules
    expose :web_home_banners
    expose :web_item_list_video
    expose :web_event_list_video
    expose :web_item_list_images
    expose :web_welcome_video
    expose :web_welcome_image
    expose :mall_tips
    expose :direct_refund_reasons
    expose :after_sale_reasons
    expose :member_bg_image
    expose :user_default_avatar
    expose :order_analyses_notify_emails
    expose :payment_settings
    expose :stock_short_quantity
    expose :android_sms_public_url
    expose :sms_platform
    expose :android_sms_notification_emails
    expose :payment_callback_timeout_emails
    expose :watermark_attributes
    expose :newbie_coupon_templates
    expose :newbie_coupon_template_ids
    expose :web_newbie_coupon_template_ids
    expose :web_newbie_coupon_templates
    expose :invited_coupon_templates
    expose :invited_coupon_template_ids
    expose :web_invited_coupon_templates
    expose :web_invited_coupon_template_ids
    expose :invitation
    expose :finish_order_coupon_template_ids_to_inviter
    expose :finish_order_coupon_templates
    expose :web_finish_order_coupon_template_ids_to_inviter
    expose :web_finish_order_coupon_templates
    expose :info_finished_coupon_template_id
    expose :info_finished_coupon_template
    expose :web_info_finished_coupon_template_id
    expose :web_info_finished_coupon_template
    expose :birthday_coupon_template_id
    expose :birthday_coupon_template
    expose :web_birthday_coupon_template_id
    expose :web_birthday_coupon_template
    expose :app_version
    expose :format_cutoff_time_response, as: :cutoff_time
    expose :same_day_delivery_cutoff_time
    expose :format_customer_services_response, as: :customer_services
    expose :merchant_delivery_orders_limit_every_day
    expose :allow_comments
    expose :cart_empty_image
    expose :order_creation_disabled
    expose :shopline_order_creation_disabled
    expose :delivery_type_settings
    expose :search_placeholder
    expose :sku_cost_minimum_factor
    expose :ae_sku_cost_minimum_factor
    expose :sku_minimum_profit_in_cent
    expose :sku_minimum_profit_in_yuan
    expose :sku_price_exception_emails
    expose :integral_special_period_rule
    expose :order_buyer_message_placeholder
    expose :new_user_custom_page_id
    expose :new_user_custom_page
    expose :new_user_message_text
    expose :order_finished_reward_integral
    expose :risk_pay_enabled
    expose :auction_enabled
    expose :value_added_service_settings
    expose :kuaima_delivery_max_count
    expose :store_invite_page_banner
    expose :shopline_price_rate
    expose :bottom_settings
    expose :ae_order_gst_percent
    expose :go_back_to_ebest_right_icon_settings
    expose :go_back_to_ebest_category_icon_settings
    expose :go_back_to_ebest_bottom_icon_settings
    expose :order_box_regulation_settings
    expose :order_package_settings

    def format_cutoff_time_response
      object.cutoff_time.map { |time| eval(time) }
    end

    def format_customer_services_response
      object.customer_services.map { |service| eval(service) }
    end
  end
end
