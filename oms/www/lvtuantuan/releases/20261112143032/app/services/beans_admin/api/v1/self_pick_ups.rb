# frozen_string_literal: true

module BeansAdmin
  class API::V1::SelfPickUps < ::API

    namespace :self_pick_ups, desc: "自提点 API" do

      helpers do
        def permitted_params
          [
            :name, :address, :mobile, :google_place_id, :province_name, :street_number, :street,
            :city_name, :opening_hours, :postal_code, :latitude, :longitude, :email, :store_id,
            :self_pick_orders_limit_every_day, :enabled, :support_same_day_delivery, weekdays: [], time_period: []
          ]
        end
      end

      desc "自提点列表", {
        success: API::Entities::SelfPickUp,
        is_array: true
      }
      paginate
      params do
        optional :name_cont, types: String, desc: "名称搜索"
      end
      get do
        authorize_and_response_collection
      end

      desc "新增自提点", {
        success: API::Entities::SelfPickUp
      }
      params do
        requires :all, using: API::Entities::SelfPickUp.documentation.slice(
          :name, :mobile, :address, :email, :province_name, :city_name, :google_place_id, :enabled,
          :opening_hours, :latitude, :longitude, :postal_code, :street, :street_number, :self_pick_orders_limit_every_day
        )
        requires :weekdays, type: Array, desc: "星期数数组"
        requires :time_period, type: Array, desc: "时间段数组"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "自提点详情", {
          success: API::Entities::SelfPickUp
        }
        get do
          authorize_and_response_resource
        end

        desc "更新商品自提点", {
          success: API::Entities::SelfPickUp,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::SelfPickUp.documentation.slice(
            :name, :mobile, :address, :email, :province_name, :city_name, :google_place_id, :enabled, :same_day_delivery,
            :opening_hours, :latitude, :longitude, :postal_code, :street, :street_number, :self_pick_orders_limit_every_day
          )
          optional :weekdays, type: Array, desc: "星期数数组"
          optional :time_period, type: Array, desc: "时间段数组"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除商品自提点", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
