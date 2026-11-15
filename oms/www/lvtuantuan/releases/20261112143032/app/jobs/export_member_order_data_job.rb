# frozen_string_literal: true

class ExportMemberOrderDataJob < ApplicationJob
  queue_as :mailers

  def perform
    `rake mailer:mailer_member_order_data_export`
  end
end
