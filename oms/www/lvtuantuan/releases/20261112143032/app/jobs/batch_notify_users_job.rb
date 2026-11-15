# frozen_string_literal: true

class BatchNotifyUsersJob < ApplicationJob
  queue_as :mailers

  def perform(file_url, admin_user)
    MagicBean::AppTextMessage.batch_notify(file_url, admin_user)

    # 删除在线文件
    Aws::CustomOss.delete_file(file_url)
  end
end
