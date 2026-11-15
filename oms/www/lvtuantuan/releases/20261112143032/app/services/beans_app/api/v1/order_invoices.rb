# frozen_string_literal: true

module BeansApp
  class API::V1::OrderInvoices < ::API
    namespace :order_invoices, desc: "订单发票API" do
      desc "生成发票", {
        summary: "生成发票",
        success: API::Entities::OrderInvoice,
      }
      params do
        requires :order_id, type: Integer
        requires :invoice_id, type: Integer
      end
      post do
        @resource = end_of_association_chain.new(order_id: params[:order_id])

        authorize_and_run_member_action(:create, { method: :generate }, invoice_id: params[:invoice_id])
      end
    end
  end
end
