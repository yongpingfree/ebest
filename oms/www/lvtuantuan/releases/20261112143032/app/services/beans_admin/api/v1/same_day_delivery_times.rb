# frozen_string_literal: true
module BeansAdmin
  class API::V1::SameDayDeliveryTimes < ::API

    namespace :same_day_delivery_times, desc: "当日达配送时间 API" do
      helpers do
        def permitted_params
            [:name, :limited_by_orders_limit_every_day, weekdays: [], same_day_delivery_time_periods_attributes: [:id, :time_period, :kind, :time_window, :enabled, :address_count_limit, :free_shipping_amount_in_yuan, :extra_shipping_amount_in_yuan, :_destroy]]
        end

        def includes
          [:delivery_areas]
        end
      end

      desc "当日达配送时间列表", {
        success: API::Entities::SameDayDeliveryTime,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建当日达配送时间", {
        success: API::Entities::SameDayDeliveryTime
      }
      params do
        requires :name, type: String, desc: "name"
        requires :weekdays, type: Array, desc: "星期数数组"
        optional :limited_by_orders_limit_every_day, type: Boolean, desc: "受限于自派订单每日派送量上限"
        optional :delivery_area_ids, type: Array, desc: "配送区域id数组"
        requires :same_day_delivery_time_periods_attributes, type: Array do
          requires :all, using: API::Entities::SameDayDeliveryTimePeriod.documentation.slice(:time_period, :kind, :time_window, :address_count_limit, :enabled, :free_shipping_amount_in_cent, :free_shipping_amount_in_yuan, :extra_shipping_amount_in_cent, :extra_shipping_amount_in_yuan)
        end
      end
      post do
        authorize! :create, MagicBean::SameDayDeliveryTime
        if build_resource.save
          if params[:delivery_area_ids]
            MagicBean::DeliveryArea.where(id: params[:delivery_area_ids]).update(same_day_delivery_time_id: resource.id)
          end
          response_resource
        else
          response_record_error(resource)
        end
      end

      desc "get time period", {
        success: API::Entities::SameDayDeliveryTime
      }
      get "time_period" do
        (MagicBean::SameDayDeliveryTimePeriod.all.pluck(:time_period).flatten.map { |time| time.gsub(/\s+/, "") } + MagicBean::SameDayDeliveryTime::DEFAULT_TIME_PERIOD).uniq
      end

      route_param :id do
        desc "当日达配送时间 详情", {
          success: API::Entities::SameDayDeliveryTime
        }
        get do
          authorize_and_response_resource
        end

        desc "更新当日达配送时间", {
          success: API::Entities::SameDayDeliveryTime
        }
        params do
          optional :name, type: String, desc: "name"
          optional :weekdays, type: Array, desc: "星期数数组"
          optional :time_period, type: Array, desc: "时间段数组"
          optional :delivery_area_ids, type: Array, desc: "配送区域id数组"
          optional :limited_by_orders_limit_every_day, type: Boolean, desc: "受限于自派订单每日派送量上限"
          optional :same_day_delivery_time_periods_attributes, type: Array do
            optional :all, using: API::Entities::SameDayDeliveryTimePeriod.documentation.slice(:id, :time_period, :kind, :time_window, :address_count_limit, :enabled, :free_shipping_amount_in_cent, :free_shipping_amount_in_yuan, :extra_shipping_amount_in_cent, :extra_shipping_amount_in_yuan)
            optional :_destroy, type: Boolean
          end
        end
        put do
          authorize! :update, resource
          old_delivery_area_ids = resource.delivery_area_ids
          if resource.update(resource_params)
            delivery_area_ids = params[:delivery_area_ids]
            if delivery_area_ids.any?
              MagicBean::DeliveryArea.where(id: delivery_area_ids).update(same_day_delivery_time_id: resource.id)
            end
            delete_ids = old_delivery_area_ids - delivery_area_ids
            MagicBean::DeliveryArea.where(id: delete_ids).update(same_day_delivery_time_id: nil)
            response_resource
          else
            response_record_error(resource)
          end
        end

        desc "删除当日达配送时间", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
