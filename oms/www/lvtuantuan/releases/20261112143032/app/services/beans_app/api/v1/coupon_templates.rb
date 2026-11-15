# frozen_string_literal: true

module BeansApp
  class API::V1::CouponTemplates < ::API
    # 优惠券模板 API
    namespace :coupon_templates, desc: "优惠券模板 API" do
      helpers do
        def collection_search_sentence
          @collection = end_of_association_chain.accessible_by(current_ability).includes(includes).send(params[:type], current_store_id).ransack(ransack_params)
        end
      end

      desc "优惠券模板列表", {
        success: API::Entities::CouponTemplate,
        skip_authentication: true
      }
      params do
        requires :type, type: String, values: ["newbie", "invited", "newbie_and_invited"], desc: "优惠券类型"
      end
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :code do
        helpers do
          def find_by_key
            :code
          end

          def end_of_association_chain
            resource_class.enabled
          end
        end

        desc "优惠券模板详情", {
          success: API::Entities::CouponTemplate,
          action_type: "viewed",
          page_type: "coupon_template",
          skip_authentication: true
        }
        get do
          authorize_and_response_resource
        end

        desc "领取优惠券", {
          success: API::Entities::Coupon
        }
        params do
          optional :coupon_code, type: String, desc: "优惠券码"
        end
        post "assign_coupon" do
          authorize! :assign_coupon, resource
          result, coupon = resource.assign_coupon(current_user, params[:coupon_code])
          if result
            present coupon, with: ::BeansApp::API::Entities::Coupon
          else
            response_record_error(resource)
          end
        end

        desc "可用商品列表", {
          success: API::Entities::SimpleItem
        }
        get "items" do
          present resource.items.where(store_id: current_store_id), with: ::BeansApp::API::Entities::SimpleItem
        end
      end
    end
  end
end
