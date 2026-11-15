# frozen_string_literal: true

module MagicBean
  class OrderInvoice < ApplicationRecord
    # constants

    # concerns

    # attr related macros
    enum state: { pending: 0, success: 1, failure: 2 }

    delegate :store, :store_id, to: :order

    # association macros
    belongs_to :order

    # validation macros
    before_create :generate_no
    after_create_commit :send_to_user_email

    # callbacks

    # other macros
    ransacker :state, formatter: proc { |v| states[v] }

    # scopes

    # class methods

    # instance methods
    def generate(invoice_id:)
      errors.add(:base, I18n.t("error.order_invoice.already_created")) and return if self.class.exists?(order_id: order_id)
      errors.add(:base, I18n.t("error.order_invoice.not_invoicable_for_this_status")) and return unless order.invoicable?
      errors.add(:base, I18n.t("error.order_invoice.not_invoicable_for_auction_item")) and return if order.type == "MagicBean::AuctionOrder"
      errors.add(:base, I18n.t("error.order_invoice.not_invoicable_for_consigned_item")) and return if order.contains_not_invoicable_items?

      invoice = order.user.invoices.find(invoice_id)

      self.invoice_properties = {
        title: invoice.title,
        abn: invoice.abn,
        first_name: invoice.first_name,
        last_name: invoice.last_name,
        tel_number: invoice.tel_number,
        address: invoice.address,
        email: invoice.email
      }

      save
    end

    def generate_no
      last_order_invoice = self.class.joins(:order).where(orders: { store_id: store_id }).last
      num = (last_order_invoice ? last_order_invoice.no[-13..-1].to_i.to_i : 0) + 1

      self.no = "INV#{store.short_name}" + "%013d" % num
    end

    def send_to_user_email
      SendOrderInvoiceJob.perform_later(id)
    end
  end
end
