# frozen_string_literal: true

module BeansApp
  class API::V1::Logistics < ::API
    namespace :orders, desc: "订单物流信息 API" do
      route_param :order_id do
        helpers do
          def current_order
            @current_order ||= current_user.orders.find params[:order_id]
          end
        end
        desc "订单物流信息", {
          success: API::Entities::Logistic,
          is_array: true,
          detail:  <<-NOTES.strip_heredoc
          `data` 数据示例：

          ```json
          "data": [
            {
              "date": "02-02 11:08",
              "location": "TOORMINA NSW",
              "description": "Delivered"
            },
            {
              "date": "02-02 09:11",
              "location": "COFFS HARBOUR NSW",
              "description": "Onboard for delivery"
            },
            {
              "date": "02-02 20:13",
              "description": "In transit to next facility in SOUTH KEMPSEY NSW"
            },
            {
              "date": "02-02 15:40",
              "location": "CHULLORA NSW",
              "description": "Item processed at facility"
            },
            {
              "date": "02-02 15:10",
              "description": "Received and ready for processing"
            },
            {
              "date": "02-02 16:47",
              "description": "Shipping information approved by Australia Post"
            },
            {
              "date": "02-02 16:17",
              "description": "Shipping information received by Australia Post"
            }
          ]
          ```

          时间按照倒叙排序，即收件时间在最前面，揽件时间在最后。`ftime` 为已格式化时间，小程序端显示请使用 `ftime` 字段。
          NOTES
        }
        get "logistics" do
          present current_order.logistics, with: API::Entities::Logistic
        end
      end
    end
  end
end
