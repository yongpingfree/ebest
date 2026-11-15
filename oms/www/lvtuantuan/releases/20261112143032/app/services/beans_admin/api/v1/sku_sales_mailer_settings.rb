# frozen_string_literal: true
module BeansAdmin
  class API::V1::SkuSalesMailerSettings < ::API
    namespace :sku_sales_mailer_settings, desc: "SkuSalesMailerSettings API" do
      helpers do
        def permitted_params
          [
            :title, :receiver_emails, :cc_emails, :deliver_after_n_days, :contains_order_gift, :contains_order_pool_gift, :send_at, :send_frequency, :sku_search_type, :enabled, :store_id, :skip_zero_sales_skus,
            sku_search_conditions: [:title_contains, :supplier_name_contains, :title_and_supplier_name_condition, :only_special_sku],
            weekdays: [],
            sku_ids: []
          ]
        end

        def default_order
          ["created_at DESC"]
        end

        def includes
          [:store]
        end

        def resource_params
          params[:sku_ids] = (params[:skus] || []).map { |sku| sku["id"] }
          super
        end
      end

      desc "sku销售邮件设置列表", {
        success: API::Entities::SimpleSkuSalesMailerSetting,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建sku销售邮件设置", {
        success: API::Entities::SkuSalesMailerSetting
      }
      params do
        requires :title, type: String, desc: "邮件标题"
        requires :receiver_emails, type: String, desc: "收件人邮箱"
        optional :cc_emails, type: String, desc: "抄送人邮箱"
        requires :deliver_after_n_days, type: Integer, natural_number: true, desc: "邮件发送时间"
        requires :send_at, type: String, desc: "邮件发送时间"
        requires :send_frequency, type: String, desc: "邮件发送频率"
        optional :weekdays, type: Array[String], desc: "邮件发送时间"
        requires :sku_search_type, type: String, desc: "sku搜索类型"
        optional :enabled, type: Grape::API::Boolean, desc: "是否启用"
        optional :skip_zero_sales_skus, type: Grape::API::Boolean, desc: "是否过滤掉销量为0的sku"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "sku销售邮件设置详情", {
          success: API::Entities::SkuSalesMailerSetting
        }
        get do
          authorize_and_response_resource
        end

        desc "更新sku销售邮件设置", {
          success: API::Entities::SkuSalesMailerSetting
        }
        params do
          optional :title, type: String, desc: "邮件标题"
          optional :receiver_emails, type: String, desc: "收件人邮箱"
          optional :cc_emails, type: String, desc: "抄送人邮箱"
          optional :deliver_after_n_days, type: Integer, natural_number: true, desc: "邮件发送时间"
          optional :send_at, type: String, desc: "邮件发送时间"
          optional :send_frequency, type: String, desc: "邮件发送频率"
          optional :weekdays, type: Array[String], desc: "邮件发送星期数"
          optional :sku_search_type, type: String, desc: "sku搜索类型"
          optional :enabled, type: Grape::API::Boolean, desc: "是否启用"
          optional :skip_zero_sales_skus, type: Grape::API::Boolean, desc: "是否过滤掉销量为0的sku"
        end
        put do
          params.delete(:store_id)
          authorize_and_update_resource
        end

        desc "删除sku销售邮件设置", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
