# frozen_string_literal: true

class CreateCustomListFromExcelJob < ApplicationJob
  queue_as :default

  def perform(title, file_url, admin_user_id, store_id, klass_name, list_id)
    admin_user = MagicBean::AdminUser.find(admin_user_id)
    result = klass_name.constantize.import_from_excel(title, file_url, admin_user.email, store_id, list_id)
    CustomListMailer.notify_admin_user(admin_user.email, result).deliver_later
  end
end
