# frozen_string_literal: true

namespace :hotfix do
  desc "新建'订单完成'积分记录，还原'订单支付'类型"
  task hotfix_order_finished_integral_records: :environment do
    puts "Start hotfix order_finished integral_records"
    MagicBean::IntegralRecord.skip_callback(:create, :after, :increase_member_available_integral, raise: false)
    MagicBean::IntegralRecord.skip_callback(:create, :after, :decrease_member_blocked_integral, raise: false)
    MagicBean::IntegralRecord.order_finished.find_each do |ir|
      ir.update_columns(kind: "order_paid")
      if ir.targetable.after_sales.successful.blank?
        order_finished_ir = ir.member.create_integral_record(:order_finished, ir.targetable, ir.integral)
        order_finished_ir.update_columns created_at: ir.targetable.finished_at
      else
        ir.send :decrease_member_available_integral
        ir.send :increase_member_blocked_integral
      end
    end
    MagicBean::IntegralRecord.set_callback(:create, :after, :increase_member_available_integral, raise: false)
    MagicBean::IntegralRecord.set_callback(:create, :after, :decrease_member_blocked_integral, raise: false)
    puts "hotfix order_finished integral_records End"
  end

  desc "积分区分平台，处理已经生成的积分记录"
  task add_channel_to_integral_records: :environment do
    MagicBean::Member.all.update_all(
      {
        available_integral: 0,
        cumulative_integral: 0,
        blocked_integral: 0,
        app_available_integral: 0,
        app_cumulative_integral: 0,
        app_blocked_integral: 0
      }
    )

    # update after sale applicant type
    MagicBean::AfterSale.ransack(reason_cont: "系统发起: 部分缺货").result.update_all(applicant_type: "wms")

    MagicBean::Member.find_each do |member|
      member.integral_records.order(created_at: :asc).find_each do |integral_record|
        # 1. update channel
        channel =
          case integral_record.kind
          when "sign_up", "inviting"
            "app"
          when "order_paid", "order_finished", "refund_withdraw"
            integral_record.targetable.completed_charge_payment_channel
          else
            integral_record.targetable.channel
          end

        integral_record.update(channel: channel)
        integral_record.reload
        # 2.calculate member integral
        case integral_record.kind
        when "sign_up", "suggest", "inviting", "spent_return"
          # sign_up: 1, suggest: 5, inviting: 6, spent_return: 8
          integral_record.send :increase_member_available_integral
        when "order_paid"
          # order_paid: 2,      # 订单支付奖励，先冻结
          integral_record.send :increase_member_blocked_integral
        when "order_finished"
          # order_finished: 3,  # 订单完成奖励，冻结积分生效
          integral_record.send :increase_member_available_integral
          integral_record.send :decrease_member_blocked_integral
          integral_record.send :hidden_order_paid_integral_record
        when "refund_withdraw"
          # refund_withdraw: 4, 收回订单奖励积分（冻结积分）
          integral_record.send :decrease_member_blocked_integral
          integral_record.send :processed_order_paid_integral_record
        when "spent"
          # spent: 7, 积分抵扣
          integral_record.send :decrease_member_available_integral
        end

        integral_record.send :set_integral_quantity
      end
    end
  end
end
