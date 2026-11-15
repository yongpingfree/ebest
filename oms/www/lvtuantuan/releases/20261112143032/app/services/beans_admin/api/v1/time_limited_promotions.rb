# frozen_string_literal: true
module BeansAdmin
  class API::V1::TimeLimitedPromotions < ::API
    namespace :time_limited_promotions, desc: "限时优惠管理 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper

      helpers do
        def permitted_params
          @permitted_params ||= [
            :title, :start_at, :end_at, :enabled, :need_price_validation, :save_qty_to_promotion_price,
            time_limited_promotion_prices_attributes: [
              :id, :price_in_cent, :stock_keeping_unit_id,
              :quantity, :reserved_quantity, :original_buy_quota,
              :original_buy_quota_days, :buy_quota, :buy_quota_days,
              :position, :_destroy
            ]
          ]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge({
            store_id: current_store_id,
            need_price_validation: current_admin_user.can_not_force_update_sku_price?
          }))
        end

        def includes
          [:store]
        end

        def check_skus_store
          if params[:time_limited_promotion_prices_attributes].present?
            sku_ids = params[:time_limited_promotion_prices_attributes].map { |price| price[:stock_keeping_unit_id] }
            skus = MagicBean::StockKeepingUnit.includes(:item).where(id: sku_ids).where.not(store_id: resource.store_id)
            if skus.present?
              title = skus.map { |sku| sku.title }.join("; ")
              response_error("SKU: #{title} 不是该优惠门店SKU，请检查右上角门店再选择商品")
            end
          end
        end
      end

      desc "限时优惠活动列表", {
        success: API::Entities::SimpleTimeLimitedPromotion,
        is_array: true
      }
      paginate
      params do
        optional :title_cont, type: String, desc: "标题包含"
        optional :start_at_gteq_datetime, type: DateTime, desc: "开始时间大于等于"
        optional :end_at_lteq_datetime, type: DateTime, desc: "结束时间小于等于"
      end
      get do
        authorize_and_response_collection
      end

      desc "创建限时优惠活动", {
        success: API::Entities::TimeLimitedPromotion
      }
      params do
        requires :all, using: API::Entities::AdminUser.documentation.dup.extract!(:title, :start_at, :end_at, :enabled)
        requires :time_limited_promotion_prices_attributes, type: Array do
          requires :all, using: API::Entities::TimeLimitedPromotionPrice.documentation.slice(
            :stock_keeping_unit_id, :buy_quota, :buy_quota_days
          )
          requires :price_in_cent, type: Integer, positive_integer: true
        end
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "限时优惠活动详情", {
          success: API::Entities::TimeLimitedPromotion
        }
        get do
          authorize_and_response_resource
        end

        desc "更新限时优惠活动", {
          success: API::Entities::TimeLimitedPromotion
        }
        params do
          requires :all, using: API::Entities::AdminUser.documentation.dup.extract!(:title, :start_at, :end_at, :enabled)
          optional :time_limited_promotion_prices_attributes, type: Array do
            requires :all, using: API::Entities::TimeLimitedPromotionPrice.documentation.slice(:stock_keeping_unit_id)
            requires :price_in_cent, type: Integer, positive_integer: true
            optional :id, type: Integer
            optional :_destroy, type: Grape::API::Boolean
          end
        end
        put do
          check_skus_store
          if resource.pending_state?
            params[:need_price_validation] = current_admin_user.can_not_force_update_sku_price?
            authorize_and_update_resource
          else
            # 非pending状态，只能更新title和position
            @permitted_params = [:title, time_limited_promotion_prices_attributes: [:id, :position]]

            authorize_and_update_resource
          end
        end

        desc "启用/停用限时优惠活动", {
          success: API::Entities::TimeLimitedPromotion
        }
        params do
          requires :action, type: String, values: %w[activate finish], desc: "停用/启用"
        end
        put "state" do
          authorize! :update, resource

          action = params[:action]
          if resource.send("may_#{action}?")
            resource.send("#{action}!")
            response_resource
          else
            response_error "不能更新该优惠活动"
          end
        end

        desc "手动更新商品限时库存", {
          success: API::Entities::SuccessfulResult
        }
        put "start_sku_quantity_and_reserved_quantity" do
          authorize! :update, resource

          resource.start_sku_quantity_and_reserved_quantity

          response_resource
        end

        desc "批量导入 SKU"
        params do
          requires :users_file, type: File, desc: "Excel文件"
        end
        post "batch_import_skus" do
          authorize! :update, resource

          response_error("只能更新未开始的限时优惠活动") unless resource.pending_state?
          response_error("请先补充 email 信息，不然没法接收通知结果") if current_admin_user.email.blank?
          response_error("请选择 xlsx 文件") unless check_file_type(params[:users_file], "xlsx")
          file_path = params[:users_file][:tempfile].path
          file_name = "time_limited_promotions/#{Date.current.strftime('%y%m%d')}/#{File.basename(file_path)}"

          file_url = aws_upload!(file_path, file_name)

          BatchImportSkuToTimeLimitedPromotionJob.perform_later(resource.id, file_url, current_admin_user.id)

          response_success
        end

        desc "删除限时优惠活动", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          if resource.activated_state?
            response_error "不能删除已激活的限时优惠活动"
          end

          authorize_and_destroy_resource
        end
      end
    end
  end
end
