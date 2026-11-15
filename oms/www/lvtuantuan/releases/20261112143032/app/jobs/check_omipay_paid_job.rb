# frozen_string_literal: true

class CheckOmipayPaidJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    return unless order && order.wait_buyer_pay?

    # 订单创建时未选择支付方式，需要下个job再查询
    if order.omipay_transaction_id?
      order.check_omipay_order_paid
    else
      order.enqueue_check_omipay_paid_job
    end
  end
end
