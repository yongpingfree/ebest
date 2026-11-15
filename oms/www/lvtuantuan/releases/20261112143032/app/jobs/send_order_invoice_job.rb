# frozen_string_literal: true

class SendOrderInvoiceJob < ApplicationJob
  queue_as :default

  def perform(id, times: 1)
    order_invoice = MagicBean::OrderInvoice.find_by(id: id)

    return unless order_invoice

    begin
      OrderInvoiceMailer.send_to_user(order_invoice, order_invoice.order.user.locale).deliver_now
      order_invoice.success!
    rescue => e
      if times <= 5
        SendOrderInvoiceJob.set(wait: 5.minutes).perform_later(id, times: times + 1)
      else
        order_invoice.failure!
      end
    end
  end
end
