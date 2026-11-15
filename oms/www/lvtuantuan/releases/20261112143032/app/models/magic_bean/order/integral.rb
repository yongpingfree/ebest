# frozen_string_literal: true

class MagicBean::Order
  # 订单积分相关
  module Integral
    extend ActiveSupport::Concern

    def calculate_integral_received_from_one_yuan
      if self.paid_at && during_the_event?(self.paid_at)
        integral_special_period_rule["integral_special_rule_received_from_one_yuan"].to_i
      else
        default_site_config&.integral_received_from_one_yuan
      end
    end

    def during_the_event?(time)
      return false if integral_special_period_rule.dig("integral_special_rule_enabled") != true

      begin
        time.between?(integral_special_period_rule["integral_special_rule_started_at"], integral_special_period_rule["integral_special_rule_ended_at"])
      rescue ArgumentError
        false
      end
    end

    def max_cost_integral
      return 0 if !user_member || integral_deducted_from_one_yuan == 0
      [
        default_site_config&.max_integral_in_one_order,
        ((total_payment_in_cent - freight_in_cent - deliver_to_door_service_fee_in_cent - box_regulation_fee_in_cent - package_service_fee_in_cent) / 100.0 * integral_deducted_from_one_yuan).to_i,
        member_available_integral
      ].min
    end

    def max_cost_integral_amount_in_cent
      (max_cost_integral * 100.0 / integral_deducted_from_one_yuan) rescue 0
    end

    def integral_deducte_amount_in_cent
      (cost_integral * 100.0 / integral_deducted_from_one_yuan) rescue 0
    end

    def cost_integral_amount_in_cent
      total_payment_in_cent - payment_in_cent - gift_card_amount_in_cent
    end

    def effective_refund_integral_amount_in_cent
      after_sales.effective.sum(:return_integral_amount).to_f / integral_deducted_from_one_yuan * 100.0 rescue 0
    end

    def all_refund_withdraw_integral_records
      after_sales.successful.map(&:refund_withdraw_integral_records).flatten + integral_records.refund_withdraw
    end

    def payment_amount_with_integral
      "#{payment_in_yuan}元" + (cost_integral > 0 ? "#{cost_integral}积分" : "")
    end

    def reward_order_paid_integral
      return unless order_finished_reward_integral
      user_member.create_integral_record(:order_paid, self, completed_charge_payment_channel, reward_integral_amount) if user_member
    end

    # 积分统一用澳币来计算, 运费，手续费不计入
    def calculate_reward_integral_amount
      # 商品优惠券会直接减到total_payment_in_cent，导致这里计算为负数
      amount = (total_payment_in_cent - freight_in_cent - cost_integral_amount_in_cent - gift_card_amount_in_cent) / 100.0 * integral_received_from_one_yuan
      amount.positive? ? amount : 0
    end

    def reward_integral_amount
      order_paid_integral_records.first&.integral || calculate_reward_integral_amount
    end

    def reward_order_finished_integral
      return unless user_member
      return unless order_finished_reward_integral

      withdraw_amount = after_sales.successful.sum(:amount_in_cent) / 100.0 * integral_received_from_one_yuan
      finished_reward_integral_amount = reward_integral_amount - withdraw_amount
      user_member.create_integral_record(:order_finished, self, completed_charge_payment_channel, finished_reward_integral_amount)
    end

    def check_cost_integral
      if cost_integral > 0
        if default_site_config&.integral_deducted_from_one_yuan == 0
          errors.add(:base, I18n.t("grape.orders.current_not_support_integral"))
        else
          errors.add(:base, I18n.t("grape.orders.only_member_can_use_integral")) unless user_member
          max_integral_in_one_order = default_site_config&.max_integral_in_one_order
          if cost_integral > max_integral_in_one_order
            errors.add(:base, I18n.t("grape.orders.max_integral_in_one_order", amount: max_integral_in_one_order))
          end
          if member_available_integral < cost_integral
            errors.add(:base, I18n.t("grape.orders.insufficient_integral"))
          end
        end
      end
    end

    def member_available_integral
      @member_available_integral ||= app? ? user_member.app_available_integral : user_member.available_integral
    end

    def spend_member_available_integral
      user_member.create_integral_record(:spent, self, channel, cost_integral) if user_member && cost_integral > 0
    rescue ActiveRecord::StatementInvalid => e
      errors.add(:base, I18n.t("grape.orders.insufficient_integral"))
      raise ActiveRecord::RecordInvalid
    end

    def return_integral_amount
      cost_integral
    end
  end
end
