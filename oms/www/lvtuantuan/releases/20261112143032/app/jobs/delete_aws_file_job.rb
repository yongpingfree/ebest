# frozen_string_literal: true

class DeleteAwsFileJob < ApplicationJob
  queue_as :default

  def perform(file_url)
    # 删除在线文件
    Aws::CustomOss.delete_file(file_url)
  end
end
