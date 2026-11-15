# frozen_string_literal: true

class ExportOperationRecordJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_operation_record_export[#{options}]`
  end
end
