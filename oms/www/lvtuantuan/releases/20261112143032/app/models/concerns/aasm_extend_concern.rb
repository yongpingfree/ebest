# frozen_string_literal: true

module AASMExtendConcern
  extend ActiveSupport::Concern

  def perform_aasm_event(event)
    error_msg = I18n.t("error.common.data_sync_exception")

    if send("may_#{event}?")
      flag = false

      transaction do
        Sidekiq.redis do |redis|
          redis.multi do
            flag = send("#{event}!")
          end
        end
      end

      flag
    else
      errors.add(:base, error_msg)

      false
    end
    # 发生并发同时修改订单状态时捕捉抛出错误
  rescue AASM::InvalidTransition
    errors.add(:base,  error_msg)

    false
  rescue ActiveRecord::StatementInvalid
    errors.add(:base,  error_msg)

    false
  end
end
