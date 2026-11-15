# frozen_string_literal: true

class RefinishOrderJob < ApplicationJob
  queue_as :orders

  def perform(id)
    order = MagicBean::Order.find_by(id: id)
    order.refinish! if order && order.may_refinish?
  end
end
