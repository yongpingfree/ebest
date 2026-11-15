# frozen_string_literal: true

class CloseAfterSaleJob < ApplicationJob
  queue_as :default

  def perform(id)
    after_sale = MagicBean::AfterSale.find(id)
    if after_sale.due_time? && Time.current >= after_sale.due_time
      after_sale.close! if after_sale.may_close?
    end
  end
end
