# frozen_string_literal: true

class PushMessageJob < ApplicationJob
  queue_as :push_notification

  def perform(id)
    push_message = MagicBean::PushMessage.find_by(id: id)

    return unless push_message

    if push_message.pending? && push_message.push_at <= Time.current
      push_message.perform_aasm_event(:push)
    end
  end
end
