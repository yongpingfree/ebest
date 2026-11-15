# frozen_string_literal: true

class ConfirmOrderJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    return if order.nil?
    if order.wait_buyer_confirm_goods?
      order.receive!
    end
  end
end
