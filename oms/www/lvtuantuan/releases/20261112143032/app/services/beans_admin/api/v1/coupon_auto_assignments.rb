# frozen_string_literal: true

module BeansAdmin
  class API::V1::CouponAutoAssignments < ::API
    namespace :coupon_auto_assignments, desc: "优惠券定时发放 API" do
      helpers do
        def default_order
          ["id desc"]
        end

        def permitted_params
          [
            :start_date, :end_date, :assign_type, coupon_template_ids: [], assign_user_ids: []
          ]
        end
      end

      desc "优惠券定时发放列表", {
        success: API::Entities::SimpleCouponAutoAssignment,
        is_array: true
      }
      params do
        optional :assign_type_eq, type: String, values: ["everyone", "part"]
        optional :start_date_gteq, type: Date
        optional :end_date_lteq, type: Date
      end
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增优惠券定时发放", {
        success: API::Entities::CouponAutoAssignment
      }
      params do
        requires :all, using: API::Entities::CouponAutoAssignment.documentation.dup.extract!(:start_date, :end_date, :coupon_template_ids, :assign_type)
        optional :all, using: API::Entities::CouponAutoAssignment.documentation.dup.extract!(:assign_user_ids)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "优惠券定时发放详情", {
          success: API::Entities::CouponAutoAssignment
        }
        get do
          authorize_and_response_resource
        end

        desc "删除优惠券定时发放", {
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
