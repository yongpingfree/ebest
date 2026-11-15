# frozen_string_literal: true

module BeansApp
  class API::V1::SiteConfigs < ::API
    # 配置 API

    namespace :site_configs, desc: "配置 API" do

      desc "获取配置", {
        skip_authentication: true
      }
      get do
        default_site_config = MagicBean::SiteConfig.default_config
        @resource ||= if current_store_id.to_i.zero?
                        default_site_config
                      else
                        store_config = MagicBean::SiteConfig.find_by(store_id: current_store_id)
                        if store_config
                          # invite_page_banner 由于历史原因，混在了 `base` 字段里，需要单独处理一次
                          store_invite_page_banner = store_config.base["invite_page_banner"]

                          default_config_json = default_site_config.as_json(except: [:id, :created_at, :updated_at, :store_id, :cutoff_time, :same_day_delivery_cutoff_time, :return_receiver_properties, :newbie_coupon_template_ids, :finish_order_coupon_template_ids_to_inviter, :birthday_coupon_template_id, :info_finished_coupon_template_id, :merchant_delivery_orders_limit_every_day, :mall_tips, :cart_empty_image, :search_placeholder, :delivery_type_settings, :sku_cost_minimum_factor, :sku_minimum_profit_in_cent, :sku_price_exception_emails, :order_configs, :value_added_service_settings, :bottom_settings])
                          default_config_json.keys.each do |key|
                            store_config.send("#{key}=", default_config_json[key])
                          end

                          store_config.base["invite_page_banner"] = store_invite_page_banner

                          store_config
                        else
                          default_site_config
                        end
                      end
        @resource.base["mine_page_banner"]["path"] = JSON.parse @resource.base["mine_page_banner"]["path"] if @resource.base["mine_page_banner"]["path"].present?
        
        custom_bottom_settings = @resource.bottom_settings
        custom_bottom_settings["bottom_text"] = custom_bottom_settings.dig("bottom_text_#{I18n.locale.to_s.downcase.gsub("-", "_")}")
        if I18n.locale.to_s.include?("en")
          custom_bottom_settings["cover"] = custom_bottom_settings["cover_en"]
          custom_bottom_settings["link"] = custom_bottom_settings["link_en"]
        else
          custom_bottom_settings["cover"] = custom_bottom_settings["cover"]
          custom_bottom_settings["link"] = custom_bottom_settings["link"]
        end

        customer_services = ((@resource&.customer_services&.map { |service| eval(service) } || []) - [{}]).map do |service|
          if I18n.locale.to_s.include?("en")
            service["store_name"] = service["store_name_en"]
            service["phone_service_time"] = service["phone_service_time_en"]
            service["app_online_service_time"] = service["app_online_service_time_en"]
            service["email_service_time"] = service["email_service_time_en"]
            service["wechat_service_time"] = service["wechat_service_time_en"]
          end
          service.except("store_name_en", "phone_service_time_en", "app_online_service_time_en", "email_service_time_en", "wechat_service_time_en")
        end

        ["right", "category", "bottom"].each do |key|
          settings = @resource.send("go_back_to_ebest_#{key}_icon_settings")
          settings["name"] = settings.dig("name_#{I18n.locale.to_s.downcase.gsub("-", "_")}")
          instance_variable_set("@custom_#{key}_icon_settings", settings.except("name_en", "name_zh_cn", "name_zh_tw"))
        end

        (@resource&.attributes || {}).reverse_merge(
          subscribe_template_keys: Wechat::TemplateMessage.get_templates,
          delivery_area: MagicBean::DeliveryArea.find_by(suburb: "Sydney", postal_code: "2000"),
          stock_keeping_units_count: MagicBean::StockKeepingUnit.on_sale.count,
          default_store: MagicBean::Store.default.first,
        ).merge!(
          customer_services: customer_services,
          bottom_settings: custom_bottom_settings.except("bottom_text_en", "bottom_text_zh_cn", "bottom_text_zh_tw", "cover_en", "link_en"),
          go_back_to_ebest_right_icon_settings: @custom_right_icon_settings,
          go_back_to_ebest_category_icon_settings: @custom_category_icon_settings,
          go_back_to_ebest_bottom_icon_settings: @custom_bottom_icon_settings
        )
      end
    end
  end
end
