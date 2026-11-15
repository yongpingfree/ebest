# frozen_string_literal: true

module BeansAdmin
  class API::V1::GrouponActivities < ::API

    namespace :groupon_activities, desc: "拼团活动 API" do
      helpers do
        def default_order
          ["enabled desc", "id desc"]
        end

        def permitted_params
          [:type, :store_id, :kind, :price_in_yuan, :user_count, :start_at, :end_at, :enabled, :item_id, :is_real, :expired_hours, :wms_sync_type, :rules, sku_groupons_attributes: [:price_in_yuan, :stock_keeping_unit_id, :enabled, :id, :_destroy]]
        end

        def includes
          [:item, sku_groupons: [stock_keeping_unit: :item]]
        end
      end

      desc "拼团活动列表", {
        success: API::Entities::GrouponActivity,
        is_array: true
      }
      params do
        optional :item_title_cont, type: String, desc: "产品名字包含"
        optional :start_at_gteq_datetime, type: DateTime, desc: "开始时间开始于"
        optional :start_at_lteq_datetime, type: DateTime, desc: "开始时间结束于"
        optional :end_at_gteq_datetime, type: DateTime, desc: "结束时间开始于"
        optional :end_at_lteq_datetime, type: DateTime, desc: "结束时间结束于"
      end
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建拼团活动", {
        success: API::Entities::GrouponActivity
      }
      params do
        requires :all, using: API::Entities::GrouponActivity.documentation.dup.extract!(:type, :kind, :user_count, :start_at, :end_at, :enabled, :item_id, :expired_hours, :wms_sync_type)
        optional :is_real, type: Boolean, desc: "是否真拼团"
        optional :price_in_yuan, type: Float, desc: "拼团活动价格(元)"
        optional :sku_groupons_attributes, type: Array do
          optional :price_in_yuan, type: Float, desc: "拼团活动价格(元)"
          optional :stock_keeping_unit_id, type: Integer, desc: "SKU ID"
          optional :enabled, type: Boolean, desc: "不参与拼团"
        end
      end
      post do
        authorize_and_create_resource
      end

      desc "发布拼团活动", detail: API::Entities::SuccessfulResult
      params do
        optional :ids, type: Array[Integer], desc: "拼团活动ID"
      end
      put "publish" do
        authorize! :publish, MagicBean::GrouponActivity
        MagicBean::GrouponActivity.where(id: params[:ids]).find_each do |groupon_activity|
          # 如果更新失败，则返回错误信息
          if groupon_activity.publish == false
            response_record_error(groupon_activity)
          end
        end
        response_success
      end

      desc "取消发布拼团活动", detail: API::Entities::SuccessfulResult
      params do
        optional :ids, type: Array[Integer], desc: "拼团活动ID"
      end
      put "unpublish" do
        authorize! :unpublish, MagicBean::GrouponActivity
        MagicBean::GrouponActivity.where(id: params[:ids]).find_each do |groupon_activity|
          groupon_activity.unpublish
        end
        response_success
      end

      route_param :id do
        desc "GrouponActivity detail", {
          success: API::Entities::GrouponActivity
        }
        get do
          authorize_and_response_resource
        end

        desc "更新拼团活动", {
          success: API::Entities::GrouponActivity
        }
        params do
          optional :all, using: API::Entities::GrouponActivity.documentation.dup.extract!(:type, :kind, :user_count, :start_at, :end_at, :enabled, :item_id, :is_real, :expired_hours, :wms_sync_type)
          optional :price_in_yuan, type: Float, desc: "拼团活动价格(元)"
          optional :sku_groupons_attributes, type: Array do
            optional :price_in_yuan, type: Float, desc: "拼团活动价格(元)"
            optional :id, type: Integer, desc: "SKU拼团 ID"
            optional :enabled, type: Grape::API::Boolean, desc: "不参与拼团"
          end
        end
        put do
          authorize_and_update_resource
        end

        desc "获取拼团信息", {
          success: API::Entities::Groupon,
          is_array: true
        }
        paginate
        get "groupons" do
          present paginate(resource.groupons), with: BeansAdmin::API::Entities::Groupon
        end
      end
    end
  end
end
