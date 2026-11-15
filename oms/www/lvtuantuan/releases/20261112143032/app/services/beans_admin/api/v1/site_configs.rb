# frozen_string_literal: true

module BeansAdmin
  class API::V1::SiteConfigs < ::API

    namespace :site_configs, desc: "全站配置接口" do
      helpers do
        def permitted_params
          [
            :custom_time_zone,
            :customer_service_name,
            :web_welcome_image,
            :member_bg_image,
            :cart_empty_image,
            :stock_short_quantity,
            :android_sms_public_url,
            :sms_platform,
            :new_user_custom_page_id,
            :new_user_message_text,
            :user_default_avatar,
            :merchant_delivery_orders_limit_every_day,
            :allow_comments,
            :order_creation_disabled,
            :shopline_order_creation_disabled,
            :search_placeholder,
            :sku_cost_minimum_factor,
            :ae_sku_cost_minimum_factor,
            :sku_minimum_profit_in_yuan,
            :order_buyer_message_placeholder,
            :order_finished_reward_integral,
            :risk_pay_enabled,
            :auction_enabled,
            :birthday_coupon_template_id,
            :web_birthday_coupon_template_id,
            :info_finished_coupon_template_id,
            :web_info_finished_coupon_template_id,
            :kuaima_delivery_max_count,
            :store_invite_page_banner,
            :shopline_price_rate,
            :ae_order_gst_percent,
            sku_price_exception_emails: [],
            newbie_coupon_template_ids: [],
            web_newbie_coupon_template_ids: [],
            invited_coupon_template_ids: [],
            web_invited_coupon_template_ids: [],
            finish_order_coupon_template_ids_to_inviter: [],
            web_finish_order_coupon_template_ids_to_inviter: [],
            android_sms_notification_emails: [],
            payment_callback_timeout_emails: [],
            web_item_list_images: [],
            direct_refund_reasons: [],
            after_sale_reasons: [],
            order_analyses_notify_emails: [],
            cutoff_time: [:time, :earliest_delivery_time, :time_kind],
            customer_services: [
              :store_name, :store_name_en, :wechat, :wecom, :email, :diplay_phone, :phone, :group_id,
              :phone_service_time, :phone_service_time_en, :online_service_time, :online_service_link,
              :app_online_service_time, :app_online_service_time_en, :email_service_time, :email_service_time_en, :wechat_service_time, :wechat_service_time_en,
              user_locales: []
            ],
            same_day_delivery_cutoff_time: [:time, :display_start_at],
            invitation: {},
            return_receiver_properties: {},
            mall_tips: {},
            integral_rules: {},
            base: [
              :app_logo_name,
              :all_category_icon,
              :overseas_student_icon,
              mine_page_banner: {}
            ],
            app_version: {
              ios: {},
              android: {}
            },
            bottom_settings: {},
            order_box_regulation_settings: {},
            order_package_settings: {},
            payment_settings: [
              :wechat_service_percentage,
              :wechat_note,
              :vm_credit_card_service_percentage,
              :commweb_note,
              :unionpay_credit_card_service_percentage,
              :unionpay_note,
              :exchange_rate_rise_percentage,
              :omipay_wechat_service_percentage,
              :omipay_wechat_note,
              :omipay_alipay_service_percentage,
              :omipay_alipay_note,
              :supay_wechat_service_percentage,
              :supay_wechat_note,
              :supay_alipay_service_percentage,
              :supay_alipay_note,
              :enable_commweb_3ds_auth,
              :apple_pay_service_percentage,
              :apple_pay_note,
              :cba_apple_pay_service_percentage,
              :cba_apple_pay_note,
              :cba_google_pay_service_percentage,
              :cba_google_pay_note
            ],
            watermark_attributes: [:is_image, :watermark_image_name, :resize_p, :watermark_text, :transparency, :geography, :x_coordinate, :y_coordinate, :voffset, :size, :color, :rotate],
            delivery_type_settings: [:merchant_delivery_remark, :self_pick_remark, :express_remark],
            integral_special_period_rule: [:integral_special_rule_name, :integral_special_rule_started_at, :integral_special_rule_ended_at, :integral_special_rule_enabled, :integral_special_rule_received_from_one_yuan],
            value_added_service_settings: [:deliver_to_door_enabled, :deliver_to_door_service_fee],
            go_back_to_ebest_right_icon_settings: [
              :name_zh_cn, :name_zh_tw, :name_en, :icon, :link
            ],
            go_back_to_ebest_category_icon_settings: [
              :name_zh_cn, :name_zh_tw, :name_en, :icon, :link
            ],
            go_back_to_ebest_bottom_icon_settings: [
              :name_zh_cn, :name_zh_tw, :name_en, :icon, :link
            ]
          ]
        end

        def resource
          default_site_config = MagicBean::SiteConfig.default_config

          @resource ||= if current_store_id.to_i.zero?
                          default_site_config
                        else
                          store_config = MagicBean::SiteConfig.find_by(store_id: params[:store_id])
                          if request.request_method == "GET"
                            # invite_page_banner 由于历史原因，混在了 `base` 字段里，需要单独处理一次
                            store_invite_page_banner = store_config.base["invite_page_banner"]

                            default_config_json = default_site_config.as_json(except: [:id, :created_at, :updated_at, :store_id, :cutoff_time, :same_day_delivery_cutoff_time, :return_receiver_properties,
                                                                                       :newbie_coupon_template_ids, :web_newbie_coupon_template_ids, :finish_order_coupon_template_ids_to_inviter, :web_finish_order_coupon_template_ids_to_inviter, :info_finished_coupon_template_id, :web_info_finished_coupon_template_id, :birthday_coupon_template_id, :web_birthday_coupon_template_id,
                                                                                       :merchant_delivery_orders_limit_every_day, :store_invite_page_banner,
                                                                                       :mall_tips, :cart_empty_image, :order_creation_disabled, :shopline_order_creation_disabled, :invited_coupon_template_ids, :web_invited_coupon_template_ids,
                                                                                       :search_placeholder, :delivery_type_settings, :integral_special_period_rule, :sku_cost_minimum_factor, :ae_sku_cost_minimum_factor, :sku_minimum_profit_in_cent,
                                                                                       :sku_price_exception_emails, :new_user_custom_page_id, :new_user_message_text, :custom_time_zone, :value_added_service_settings, :shopline_price_rate, :ae_order_gst_percent, :bottom_settings, :order_box_regulation_settings, :order_package_settings])
                            default_config_json.keys.each do |key|
                              store_config.send("#{key}=", default_config_json[key])
                            end

                            store_config.base["invite_page_banner"] = store_invite_page_banner
                          end
                          store_config
                        end
        end
      end

      desc "配置详情", {
        success: API::Entities::SiteConfig
      }
      get do
        authorize_and_response_resource
      end

      route_param :id do
        desc "配置详情", {
          success: API::Entities::SiteConfig
        }
        get do
          authorize_and_response_resource
        end

        desc "更新配置", {
          success: API::Entities::SiteConfig
        }
        params do
          optional :direct_refund_reasons, type: Array[String], coerce_with: ->(val) { val.split(/[;；]/).map(&:strip) }
          optional :after_sale_reasons, type: Array[String], coerce_with: ->(val) { val.split(/[;；]/).map(&:strip) }
          optional :order_analyses_notify_emails, type: Array[String], coerce_with: ->(val) { val.split(/[;；]/).map(&:strip) }
          optional :android_sms_notification_emails, type: Array[String], coerce_with: ->(val) { val.split(/[;；]/).map(&:strip) }
          optional :payment_callback_timeout_emails, type: Array[String], coerce_with: ->(val) { val.split(/[;；]/).map(&:strip) }
          optional :sku_price_exception_emails, type: Array[String], coerce_with: ->(val) { val.split(/[;；]/).map(&:strip) }
        end
        put do
          log_message = resource.generate_log_message(resource_params)
          authorize_and_update_resource(log_message: log_message)
        end
      end
    end
  end
end
