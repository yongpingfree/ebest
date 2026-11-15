# frozen_string_literal: true

module BeansAdmin
  class API::V1::Members < ::API

    namespace :members, desc: "会员 API" do
      helpers do
        def includes
          [:user, :inviter]
        end
      end

      desc "会员列表", {
        success: API::Entities::Member,
        is_array: true
      }
      params do
        use :created_at_search
        optional :mobile_cont, type: String, desc: "电话包含"
        optional :birthday_gteq_datetime, type: DateTime, desc: "生日大于或等于"
        optional :birthday_lteq_datetime, type: DateTime, desc: "生日小于或等于"
      end
      paginate
      get do
        authorize_and_response_collection
      end

      route_param :id do
        desc "会员详情", {
          success: API::Entities::Member
        }
        get do
          authorize_and_response_resource
        end

        desc "积分记录", {
          success: API::Entities::IntegralRecord,
          is_array: true
        }
        params do
          optional :kind_eq, type: String, desc: "类型"
        end
        paginate
        get "integral_records" do
          authorize! :read, MagicBean::IntegralRecord
          present paginate(resource.integral_records.ransack(params).result.order("id desc")), with: API::Entities::IntegralRecord
        end
      end
    end
  end
end
