# frozen_string_literal: true

class ConfirmAfterSaleJob < ApplicationJob
  queue_as :default

  def perform(id)
    after_sale = MagicBean::AfterSale.find_by(id: id)
    if after_sale && after_sale.wait_seller_confirm_goods?
      after_sale.confirm!
    end
  end
end
