# frozen_string_literal: true

class OrderRefundQueryJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = MagicBean::Order.find(order_id)
    begin
      result = WxPay::Service.refund_query(out_trade_no: order.no)
      if result.success? && result.select { |k, v| k =~ /^refund_status_/ && v != WxPay::Result::SUCCESS_FLAG }.empty?
        order.close! if order.refunding?
      end
    rescue RestClient::Exceptions::Timeout
    end
  end
end
