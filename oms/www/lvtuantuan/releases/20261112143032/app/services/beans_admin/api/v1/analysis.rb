# frozen_string_literal: true

module BeansAdmin
  class API::V1::Analysis < ::API
    helpers ::BeansAdmin::Helpers::AnalysisHelper

    namespace :analysis, desc: "数据统计" do
      desc "数据统计"
      params do
        optional :channel, type: String, values: MagicBean::Order.channels.keys + ["all"], desc: "平台"
        optional :date_range, type: Array[Date], desc: "['开始时间，'结束日期']，范围：一年内"
        optional :types, type: Array[String], desc: "数据类型", documentation: { param_type: "query" }, values: %w[
          page_view user_view shop_bag_item_count orders_actually_amount_sum orders_payment_sum finished_after_sales_amount_sum
          user_finished_after_sales_amount_sum wms_finished_after_sales_amount_sum
          orders_count paid_orders_count paid_and_without_all_refund_orders_count orders_user_count paid_orders_user_count order_rate
          paid_and_without_all_refund_orders_user_count per_customer_transaction per_customer_products
          merchant_delivery_addresses_count extra_merchant_delivery_addresses_count orders_gmv_sum
        ]
      end
      get "analysis" do
        # 数据分析和商家配送分析需要各自做权限校验
        if (params[:types] & ["merchant_delivery_addresses_count", "extra_merchant_delivery_addresses_count"]).present?
          raise CanCan::AccessDenied if current_user.permissions.exclude?("merchant_delivery_addresses_analysis")
        else
          raise CanCan::AccessDenied if current_user.permissions.exclude?("data_analysis")
        end

        response_error("开始日期不可以大于结束日期") if start_date > end_date
        response_error("时间超出范围，只能统计一年内的数据") if start_date < Date.current.prev_year
        response_error("至少选择一项分析指标") unless params[:types]
        params[:types].uniq.map do |type|
          [
            type, {
              "data_source": completing_data(send("#{type}_data", params[:channel])),
              "period_data": respond_to?("#{type}_period_data") ? format_number(send("#{type}_period_data", params[:channel])) : ""
            }
          ]
        end.to_h
      end
    end
  end
end
