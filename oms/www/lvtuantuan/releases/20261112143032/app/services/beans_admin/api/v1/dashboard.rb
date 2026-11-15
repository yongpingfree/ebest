# frozen_string_literal: true

module BeansAdmin
  class API::V1::Dashboard < ::API
    namespace :dashboard, desc: "仪表盘 API" do
      desc "控制面板"
      get do
        raise CanCan::AccessDenied unless current_admin_user.permissions.include?("home")

        @top7_items = MagicBean::Item.ransack({ store_id_eq: params[:store_id_eq] }).result.reorder(sales_count: :desc).limit(7).select(:id, :title, :cover, :sales_count, :delivery_type).as_json(except: [:tag_list, :comment_tag_list])
        scene_code_count = MagicBean::Order.where.not(paid_at: nil).ransack({ store_id_eq: params[:store_id_eq] }).result.group("scene_code").count
        @order_sources = Hash[scene_code_count.map { |key, value| [Wechat::SceneCode.info(key), value] }].sort { |x, y| y[1]<=>x[1] }.to_h
        @order_scope = MagicBean::Order.recent_day(30).ransack({ store_id_eq: params[:store_id_eq] })
        @paid_and_without_all_refund_orders = @order_scope.result.paid.where("actually_amount_in_cent > 0")
        # 支付订单数趋势(支付订单数-完全退款数)
        @recent_30_paid_order_num_trend = @paid_and_without_all_refund_orders.recent_day(30).group("CAST(created_at AS DATE)").count
        # 订单总数趋势
        @recent_30_order_num_trend = @order_scope.result.group("CAST(created_at AS DATE)").count
        @app_recent_30_order_num_trend = @order_scope.result.app.group("CAST(created_at AS DATE)").count
        @mini_program_recent_30_order_num_trend = @order_scope.result.mini_program.group("CAST(created_at AS DATE)").count
        # 支付订单总额趋势(销售总额-退款金额)
        @recent_30_order_actual_amount_trend = @order_scope.result.paid.group("CAST(created_at AS DATE)").sum(:actually_amount_in_cent).transform_values { |v| v / 100.0 }
        # 销售总额趋势(所有支付金额总和)
        @recent_30_order_paid_amount_trend = @order_scope.result.paid.group("CAST(created_at AS DATE)").sum(:payment_in_cent).transform_values { |v| v / 100.0 }
        @app_recent_30_order_paid_amount_trend = @order_scope.result.paid.app.group("CAST(created_at AS DATE)").sum(:payment_in_cent).transform_values { |v| v / 100.0 }
        @mini_program_recent_30_order_paid_amount_trend = @order_scope.result.paid.mini_program.group("CAST(created_at AS DATE)").sum(:payment_in_cent).transform_values { |v| v / 100.0 }

        {
          todo_items: {
            wait_send_goods_count: {
              normal_order: MagicBean::NormalOrder.ransack({ store_id_eq: params[:store_id_eq] }).result.wait_seller_send_goods.count,
              groupon_order: MagicBean::GrouponOrder.ransack({ store_id_eq: params[:store_id_eq] }).result.wait_seller_send_goods.count
            },
            pending_after_sales_count: MagicBean::AfterSale.ransack({ store_id_eq: params[:store_id_eq] }).result.wait_seller_agree.count,
            pending_comment_count: MagicBean::Comment.top_level.pending.count,
            pending_user_suggestion_count: MagicBean::UserSuggestion.pending.count
          },
          recent_30_order_trend: {
            order_num_trend: @recent_30_order_num_trend,
            app_order_num_trend: @app_recent_30_order_num_trend,
            mini_program_order_num_trend: @mini_program_recent_30_order_num_trend,
            paid_order_num_trend: @recent_30_paid_order_num_trend,
            order_actual_amount_trend: @recent_30_order_actual_amount_trend,
            order_paid_amount_trend: @recent_30_order_paid_amount_trend,
            app_order_paid_amount_trend: @app_recent_30_order_paid_amount_trend,
            mini_program_order_paid_amount_trend: @mini_program_recent_30_order_paid_amount_trend
          },
          order_data_overview: {
            order_sum_pay_amnount: MagicBean::Order.ransack({ store_id_eq: params[:store_id_eq] }).result.paid.actually_amount_in_yuan_sum,
            today_order_count: @paid_and_without_all_refund_orders.today.count,
            today_order_pay_amount: @paid_and_without_all_refund_orders.today.actually_amount_in_yuan_sum,
            recent_7_day_order_count: @paid_and_without_all_refund_orders.recent_day(7).count,
            recent_7_day_order_pay_amount: @paid_and_without_all_refund_orders.recent_day(7).actually_amount_in_yuan_sum,
            user_count: MagicBean::User.ransack({ selected_store_id_eq: params[:store_id_eq] }).result.count,
            today_new_user_count: MagicBean::User.today.ransack({ selected_store_id_eq: params[:store_id_eq] }).result.count
          },
          order_sources: @order_sources,
          top7_items: @top7_items
        }
      end

      get "page_visited_source" do
        raise CanCan::AccessDenied unless current_admin_user.permissions.include?("home")

        @page_visited_source = MagicBean::History.page_visited_source(params[:store_id_eq])

        { page_visited_source: @page_visited_source }
      end
    end
  end
end
