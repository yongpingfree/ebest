# frozen_string_literal: true

module BeansApp
  class API::V1::PromoCodes < ::API
    # 优惠券 API

    namespace :promo_codes, desc: "Promo Code API" do
      route_param :code do
        helpers do
          def find_by_key
            :code
          end

          def end_of_association_chain
            resource_class.active
          end

          def resource
            @resource ||= end_of_association_chain.find_by("#{find_by_key}" => format_code)
          end

          def format_code
            params[find_by_key].to_s.strip
          end
        end

        desc "Promo Code 详情", {
          success: API::Entities::PromoCode
        }
        get do
          # 先判断code是否是免邮code
          if format_code == MagicBean::Order::FREE_SHIPPING_CODE
            current_store = MagicBean::Store.find(current_store_id)
            if MagicBean::Order.can_use_free_shipping_code?(ebest_channel, current_user, current_store.current_time_zone)
              response_success
            else
              response_error I18n.t("error.order.free_shipping_code_only_for_web_new_user")
            end
          else
            if resource
              response_error(I18n.t("grape.promo_codes.only_for_new_user")) unless resource.user_valid?(current_user)
              response_error(I18n.t("grape.promo_codes.use_time_invalid")) unless resource.use_time_valid?(current_user)
              authorize_and_response_resource
            else
              response_error(I18n.t("grape.promo_codes.invalid"))
            end
          end
        end
      end
    end
  end
end
