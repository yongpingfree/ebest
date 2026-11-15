# frozen_string_literal: true

# 针对payment进行查询
class CheckCommwebPaidJob < ApplicationJob
  queue_as :orders

  def perform(id, entity_name = "MagicBean::CommwebPayment")
    payment = "#{entity_name}".constantize.find_by(id: id)
    return unless payment

    order = payment.paymentable
    return unless order.wait_buyer_pay? || order.risk_pay?

    if !payment.check_commweb_payment_paid
      payment.enqueue_check_commweb_paid_job
    end
  end
end
