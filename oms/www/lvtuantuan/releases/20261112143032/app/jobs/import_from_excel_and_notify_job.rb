# frozen_string_literal: true

class ImportFromExcelAndNotifyJob < ApplicationJob
  queue_as :default

  def perform(model_name, file_url, admin_user_id)
    klass = model_name.constantize

    if klass.respond_to?(:import_from_excel_and_notify)
      klass.import_from_excel_and_notify(file_url, admin_user_id)
    end
  end
end
