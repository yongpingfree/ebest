# frozen_string_literal: true

class ApplePayOrderQueryJob < ApplicationJob
  queue_as :orders

  def perform(payment_id)
    resource =  MagicBean::Payment.find_by(id: payment_id)

    resource.query if resource && resource.pending?
  end
end
