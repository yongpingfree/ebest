# frozen_string_literal: true
module BeansAdmin
  class API::V1::DeliveryTimes < ::API

    namespace :delivery_times, desc: "MagicBean::DeliveryTimes API" do
      helpers do
        def permitted_params
          [
            :name, :limited_by_orders_limit_every_day,
            delivery_time_periods_attributes: [
              :id, :title_zh_cn, :title_zh_tw, :title_en, :_destroy,
              delivery_time_period_settings_attributes: [:id, :prefer_time, :order_address_limit_every_day, :freight_in_yuan, :_destroy]
            ],
            weekdays: []
          ]
        end

        def includes
          [:delivery_areas]
        end

        def resource
          @resource ||= end_of_association_chain.includes([delivery_time_periods: [:translations, :delivery_time_period_settings]]).find_by!("#{find_by_key}" => params[find_by_key])
        end
      end

      desc "MagicBean::DeliveryTimes list", {
        success: API::Entities::SimpleDeliveryTime,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "Create delivery_time", {
        success: API::Entities::DeliveryTime
      }
      params do
        requires :name, type: String, desc: "name"
        requires :weekdays, type: Array, desc: "星期数数组"
        optional :limited_by_orders_limit_every_day, type: Boolean, desc: "受限于自派订单每日派送量上限"
        optional :delivery_area_ids, type: Array, desc: "配送区域id数组"
        requires :delivery_time_periods_attributes, type: Array do
          requires :all, using: API::Entities::DeliveryTimePeriod.documentation.slice(:title_zh_cn, :title_tw, :title_en)
          requires :delivery_time_period_settings_attributes, type: Array, desc: "时间段设置数组" do
            requires :all, using: API::Entities::DeliveryTimePeriodSetting.documentation.slice(:prefer_time, :order_address_limit_every_day, :freight_in_yuan)
          end
        end
      end
      post do
        authorize! :create, MagicBean::DeliveryTime
        if build_resource.save
          if params[:delivery_area_ids]
            MagicBean::DeliveryArea.where(id: params[:delivery_area_ids]).update(delivery_time_id: resource.id)
          end
          response_resource
        else
          response_record_error(resource)
        end
      end

      desc "get time period", {
        success: API::Entities::DeliveryTime
      }
      get "time_period" do
        MagicBean::SelfPickUp::TIME_PERIOD
      end

      route_param :id do
        desc "DeliveryTime detail", {
          success: API::Entities::DeliveryTime
        }
        get do
          authorize_and_response_resource
        end

        desc "Update delivery_time", {
          success: API::Entities::DeliveryTime
        }
        params do
          optional :name, type: String, desc: "name"
          optional :weekdays, type: Array, desc: "星期数数组"
          optional :delivery_area_ids, type: Array, desc: "配送区域id数组"
          optional :limited_by_orders_limit_every_day, type: Boolean, desc: "受限于自派订单每日派送量上限"
          optional :delivery_time_periods_attributes, type: Array do
            optional :all, using: API::Entities::DeliveryTimePeriod.documentation.slice(:id, :title_zh_cn, :title_tw, :title_en)
            optional :_destroy, type: Boolean
            optional :delivery_time_period_settings_attributes, type: Array, desc: "时间段设置数组" do
              optional :all, using: API::Entities::DeliveryTimePeriodSetting.documentation.slice(:id, :prefer_time, :order_address_limit_every_day, :freight_in_yuan)
              optional :_destroy, type: Boolean
            end
          end
        end
        put do
          authorize! :update, resource
          old_delivery_area_ids = resource.delivery_area_ids
          if resource.update(resource_params)
            delivery_area_ids = params[:delivery_area_ids]
            if delivery_area_ids.any?
              MagicBean::DeliveryArea.where(id: delivery_area_ids).update(delivery_time_id: resource.id)
            end
            delete_ids = old_delivery_area_ids - delivery_area_ids
            MagicBean::DeliveryArea.where(id: delete_ids).update(delivery_time_id: nil)
            response_resource
          else
            response_record_error(resource)
          end
        end

        desc "Destroy delivery_time", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end

        desc "Get Order Delivery Count",  {
          success: API::Entities::SuccessfulResult
        }
        params do
          requires :delivery_date, type: String, desc: "派送日期"
        end

        get "orders_count" do
          authorize! :read, resource

          count = MagicBean::Order.merchant_delivery.wait_seller_send_goods.where(delivery_date: params[:delivery_date], delivery_time_id: resource.id).count
          address_count = MagicBean::Order.merchant_delivery.wait_seller_send_goods.where(delivery_date: params[:delivery_date], delivery_time_id: resource.id).select("distinct receiver_properties").count
          response_success("id: #{resource.id}, 配送日期: #{params[:delivery_date]}, 订单数: #{count}, 地址数: #{address_count}")
        end

        desc "Get Delivery Time Period Settings", {
          success: BeansAdmin::API::Entities::DeliveryTimePeriodSetting
        }
        get "delivery_time_period_settings" do
          authorize! :read, resource
          present resource.delivery_time_period_settings.order(:id), with: BeansAdmin::API::Entities::DeliveryTimePeriodSetting
        end
      end
    end
  end
end
