# frozen_string_literal: true

module BeansAdmin
  class API::V1::OrderPaidAnalyses < ::API
    helpers ::BeansAdmin::Helpers::OrderPaidAnalysesHelper

    namespace :order_analyses, desc: "订单数据统计" do
      desc "数据统计"
      params do
        optional :date_range, type: Array[Date], desc: "['开始时间，'结束日期']，范围：一年内"
      end
      get do
        response_error("开始日期不可以大于结束日期") if start_date > end_date
        response_error("时间超出范围，只能统计一年内的数据") if start_date < Date.current.prev_year || end_date > Date.current

        {
          app: analysis_data("app"),
          mini_program: analysis_data("mini_program")
        }
      end
    end
  end
end
