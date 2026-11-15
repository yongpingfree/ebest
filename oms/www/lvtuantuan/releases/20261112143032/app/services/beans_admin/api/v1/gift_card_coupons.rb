# frozen_string_literal: true
module BeansAdmin
  class API::V1::GiftCardCoupons < ::API

    namespace :gift_card_coupons, desc: "礼品券API" do
      helpers do
        def current_gift_card_template
          @current_gift_card_template ||= MagicBean::GiftCardTemplate.store_ids_contains(current_store_ids).find(params[:gift_card_template_id_eq])
        end

        def current_store_ids
          @current_store_ids = params[:store_id].present? ? [params[:store_id]] : "all"
        end
      end

      before do
        authorize! :read, current_gift_card_template
      end

      desc "礼品券列表", {
        success: API::Entities::GiftCardCoupon,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "导出礼品卡列表"
      get "export" do
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        options = {
          email: current_admin_user.email,
          order_by: params[:order_by] || default_order,
          ransack_params: ransack_params
        }

        options = encrypt_params(options)

        ExportGiftCardJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      route_param :id do
        desc "礼品券详情", {
          success: API::Entities::GiftCardCoupon
        }
        get do
          authorize_and_response_resource
        end

        desc "删除礼品券", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
