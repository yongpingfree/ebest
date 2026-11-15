# frozen_string_literal: true

class UnionPayQueryJob < ApplicationJob
  queue_as :payment

  def perform(id)
    resource =  MagicBean::Payment.find_by(id: id)

    resource.query if resource && resource.pending?
  end
end
