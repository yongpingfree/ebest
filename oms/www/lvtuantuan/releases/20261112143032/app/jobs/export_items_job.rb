# frozen_string_literal: true

class ExportItemsJob < ApplicationJob
  queue_as :mailers

  def perform(options)
    `rake mailer:mailer_items_export[#{options}]`
  end
end
