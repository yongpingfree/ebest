# frozen_string_literal: true

module BeansAdmin
  class API::V1::GiftActivities < ::API

    namespace :gift_activities, desc: "赠品活动 API" do
      helpers do
        def default_order
          ["status asc", "id desc"]
        end

        def permitted_params
          [:start_at, :end_at, :status, :store_id, rules: [:price_gradient, :all_give, :coupon_template_id, :coupon_and_skus_all_give, skus: [:sku_id, :quantity, :not_support_express, :position]]]
        end
      end

      desc "赠品活动 列表", {
        success: API::Entities::GiftActivity,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建 赠品活动", {
        success: API::Entities::GiftActivity
      }
      params do
        requires :all, using: API::Entities::GiftActivity.documentation.dup.extract!(:start_at, :end_at, :status)
        requires :rules, type: Array do
          requires :price_gradient, type: Float, desc: "满送金额(元)"
          optional :skus, type: Array do
            optional :sku_id, type: Integer, desc: "SKU ID"
            optional :quantity, type: Integer, desc: "SKU 数量"
            optional :not_support_express, type: Boolean, desc: "不支持邮寄"
            optional :position, type: Integer, desc: "位置"
          end
          optional :coupon_template_id, type: Integer, desc: "优惠券 ID"
        end
      end
      post do
        authorize_and_create_resource
      end

      desc "启用 赠品活动", detail: API::Entities::SuccessfulResult
      params do
        optional :ids, type: Array[Integer], desc: "赠品活动 ID"
      end
      put "enabled" do
        authorize! :enabled, MagicBean::GiftActivity
        MagicBean::GiftActivity.where(id: params[:ids]).find_each do |gift_activity|
          # 如果更新失败，则返回错误信息
          gift_activity.enabled! rescue response_record_error(gift_activity)
        end
        response_success
      end

      desc "停用 赠品活动", detail: API::Entities::SuccessfulResult
      params do
        optional :ids, type: Array[Integer], desc: "赠品活动 ID"
      end
      put "disabled" do
        authorize! :disabled, MagicBean::GiftActivity
        MagicBean::GiftActivity.where(id: params[:ids]).map(&:disabled!)
        response_success
      end

      route_param :id do
        desc "赠品活动 详情", {
          success: API::Entities::GiftActivity
        }
        get do
          authorize_and_response_resource
        end

        desc "更新 赠品活动", {
          success: API::Entities::GiftActivity,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::GiftActivity.documentation.dup.extract!(:start_at, :end_at, :status)
          optional :rules, type: Array do
            optional :price_gradient, type: Float, desc: "满送金额(元)"
            optional :skus, type: Array do
              optional :sku_id, type: Integer, desc: "SKU ID"
              optional :quantity, type: Integer, desc: "SKU 数量"
              optional :not_support_express, type: Boolean, desc: "不支持邮寄"
            end
            optional :coupon_template_id, type: Integer, desc: "优惠券 ID"
          end
        end
        put do
          authorize_and_update_resource
        end

        desc "删除 赠品活动", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
