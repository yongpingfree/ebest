 # frozen_string_literal: true

module RefundIntegralConcern
  extend ActiveSupport::Concern

  def withdraw_and_return_integral
    withdraw_order_paid_integral
    return_used_integral
  end

  # 扣除会员购买时获得的冻结积分
  def withdraw_order_paid_integral
    return unless payment_has_integral?

    withdraw_amount =
      if self.is_a?(MagicBean::Order)
        self.reward_integral_amount
      else
        amount_in_cent / 100.0 * order.integral_received_from_one_yuan
      end

    if user_member && reward_integral_amount >= 1
      user_member.create_integral_record(:refund_withdraw, self, completed_charge_payment_channel, withdraw_amount)
    end
  end

  def return_used_integral
    if user_member
      user_member.reload.create_integral_record(:spent_return, self, original_spent_channel, return_integral_amount)
    end
  end

  def payment_has_integral?
    @payment_has_integral ||= (self.is_a?(MagicBean::Order) ? order_finished_reward_integral : self.order.order_finished_reward_integral)
  end
end
