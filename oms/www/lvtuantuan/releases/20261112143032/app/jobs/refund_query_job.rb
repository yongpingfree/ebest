# frozen_string_literal: true

class RefundQueryJob < ApplicationJob
  queue_as :payment

  def perform(id)
    resource = MagicBean::Payment.find_by(id: id)

    resource.refund_query if resource && !resource.completed?
  end
end
