# frozen_string_literal: true

module BeansApp
  class API::V1::SelfPickUps < ::API

    namespace :self_pick_ups, desc: "自提点API" do

      helpers do
        def default_order
          # if params[:current_location].present?
          #   "distance ASC"
          # else
          #   super
          # end

          # TODO 此为暂时排序
          ["id asc"]
        end

        def end_of_association_chain
          if params[:current_location].present?
            resource_class.near(params[:current_location], 30000, units: :km)
          else
            super
          end.active
        end
      end

      desc "自提点列表", {
        success: API::Entities::SelfPickUp,
        is_array: true
      }
      paginate
      params do
        # TODO: 这里为了兼容线上版本先改为optional, 后面再改为require
        optional :order_store_id, type: Integer, desc: "订单store_id"
        optional :keyword, as: :name_or_address_cont, type: String, desc: "自提点名称或地址"
        optional :current_location, type: Array[String], desc: "当前地址经纬度，例如：[-34.11,143.22]，传了这个参数即会按照距离近优先排序"
        optional :support_same_day_delivery_eq, type: Boolean, desc: "是否支持当日达，当日达订单需要传true，普通订单不用传"
      end
      get do
        params[:store_id_eq] = params[:order_store_id]
        authorize_and_response_collection
      end
    end
  end
end
