# frozen_string_literal: true

require "wicked_pdf"

class OrderInvoiceMailer < ApplicationMailer
  def send_to_user(order_invoice, user_locale)
    @order_invoice = order_invoice
    pdf_html = ActionController::Base.new.render_to_string(template: "order_invoice_mailer/invoice_pdf", layout: "mailer", locals: { order_invoice: @order_invoice })
    pdf = WickedPdf.new.pdf_from_string(pdf_html)
    attachments["发票#{@order_invoice.no}.pdf"] = pdf

    I18n.with_locale(user_locale) do
      mail(to: order_invoice.invoice_properties["email"], subject: I18n.t("order_invoice_mailer.send_to_user.title", number: order_invoice.order.no))
    end
  end
end
