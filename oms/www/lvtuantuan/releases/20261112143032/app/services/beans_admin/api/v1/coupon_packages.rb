# frozen_string_literal: true
module BeansAdmin
  class API::V1::CouponPackages < ::API

    namespace :coupon_packages, desc: "CouponPackages API" do
      helpers do
        def permitted_params
          [:name, :status, :user_kind, :cover, :start_at, :end_at, :store_id, coupon_template_ids: []]
        end
      end

      desc "CouponPackages list", {
        success: API::Entities::CouponPackage,
        is_array: true
      }
      paginate
      params do
        optional :name_cont, type: String
      end
      get do
        authorize_and_response_collection
      end

      desc "Create coupon_package", {
        success: API::Entities::CouponPackage
      }
      params do
        requires :name, type: String, desc: "name"
        requires :user_kind, type: String, values: MagicBean::CouponPackage.user_kinds.keys, desc: "用户类型"
        requires :coupon_template_ids, type: Array[Integer], desc: "优惠券模板 ids"
        requires :cover, type: String, desc: "封面"
        optional :start_at, type: String, desc: "开始时间"
        optional :end_at, type: String, desc: "结束时间"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "CouponPackage detail", {
          success: API::Entities::CouponPackage
        }
        get do
          authorize_and_response_resource
        end

        desc "Update coupon_package", {
          success: API::Entities::CouponPackage,
          skip_store_id: true
        }
        params do
          optional :name, type: String, desc: "name"
          optional :user_kind, type: String, values: MagicBean::CouponPackage.user_kinds.keys, desc: "用户类型"
          optional :coupon_template_ids, type: Array[Integer], desc: "优惠券模板 ids"
          optional :cover, type: String, desc: "封面"
          optional :start_at, type: String, desc: "开始时间"
          optional :end_at, type: String, desc: "结束时间"
        end
        put do
          authorize_and_update_resource
        end

        desc "发布/停用优惠券礼包", {
          success: API::Entities::CouponPackage
        }
        put "toggle_state" do
          authorize_and_run_member_action(:toggle_state)
        end

        desc "Destroy coupon_package", detail: API::Entities::SuccessfulResult
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
