# frozen_string_literal: true

class AfterSaleRefundQueryJob < ApplicationJob
  queue_as :default

  def perform(after_sale_id)
    after_sale = MagicBean::AfterSale.find(after_sale_id)
    begin
      result = WxPay::Service.refund_query(out_refund_no: after_sale.refund_no)
      if result.success? && result.select { |k, v| k =~ /^refund_status_/ && v != WxPay::Result::SUCCESS_FLAG }.empty?
        after_sale.drawback! if after_sale.refunding?
      end
    rescue RestClient::Exceptions::Timeout
    end
  end
end
