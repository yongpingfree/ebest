# frozen_string_literal: true

class FinishOrderJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    order.finish! if order && order.buyer_confirm_goods?
  end
end
