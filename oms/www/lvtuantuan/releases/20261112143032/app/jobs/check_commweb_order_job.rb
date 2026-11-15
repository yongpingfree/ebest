# frozen_string_literal: true

# 针对order进行查询
class CheckCommwebOrderJob < ApplicationJob
  queue_as :orders

  def perform(id, cba_transaction_id, entity, ebest_channel)
    order = MagicBean::Order.find id
    return unless order && (order.wait_buyer_pay? || order.risk_pay?)

    # TODO: 需要重构
    api_class = "Commweb::#{order.target_api_name(entity)}".constantize
    logger = order.custom_logger(entity)
    retrieve_resp = api_class.retrieve_transaction(order.no, cba_transaction_id, ebest_channel)
    logger.info("order id: #{id} retrieve resp: #{retrieve_resp}")

    risk_resp = retrieve_resp["risk"]
    if order.risk_pay_enabled && risk_resp.present? && risk_resp["response"]["gatewayCode"] == "REVIEW_REQUIRED" && risk_resp["response"]["review"]["decision"].upcase != "ACCEPTED"
      if risk_resp["response"]["review"]["decision"].upcase == "PENDING"
        order.risk! if order.wait_buyer_pay?
        # 超时支付回调到不了这里，所以无需发邮件

        CheckCommwebOrderJob.set(wait: 10.minutes).perform_later(id, cba_transaction_id, entity, ebest_channel)
      else
        # TODO: 关闭子单
        order.close!
      end
    else
      if retrieve_resp["result"] == "SUCCESS"
        order.commweb_success_handle(retrieve_resp, ebest_channel, entity)
      elsif retrieve_resp["result"] == "FAILURE"
        order.update_columns(payment_in_progress: false)
      else
        CheckCommwebOrderJob.set(wait: 10.second).perform_later(id, cba_transaction_id, entity, ebest_channel)
      end
    end
  end
end
