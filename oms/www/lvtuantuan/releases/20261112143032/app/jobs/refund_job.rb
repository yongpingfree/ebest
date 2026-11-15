# frozen_string_literal: true

class RefundJob < ApplicationJob
  queue_as :payment

  def perform(id)
    resource = MagicBean::Payment.find_by(id: id)

    resource.refund! if resource && !resource.completed?
  end
end
