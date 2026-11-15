# frozen_string_literal: true

class MarketingMessageJob < ApplicationJob
  queue_as :push_notification

  def perform(id)
    marketing_message = MagicBean::MarketingMessage.find_by(id: id)

    return unless marketing_message

    if marketing_message.pending? && marketing_message.push_at <= Time.current
      marketing_message.perform_aasm_event(:push)
    end
  end
end
