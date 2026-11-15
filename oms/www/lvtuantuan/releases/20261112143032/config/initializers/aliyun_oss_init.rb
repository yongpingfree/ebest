# frozen_string_literal: true

require "aliyun/oss"

module OSS
  def self.client
    unless @client
      Aliyun::Common::Logging.set_log_file("./log/oss_sdk.log")

      aliyun_config = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun)

      @client = Aliyun::OSS::Client.new(
        endpoint: aliyun_config[:oss_endpoint],
        access_key_id: aliyun_config[:access_key_id],
        access_key_secret: aliyun_config[:secret_access_key]
      )
    end

    @client
  end

  def self.delete(file_url, format_url = true)
    file_key = format_url ? URI(file_url).path[1..-1] : file_url
    bucket_name = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun, :oss_bucket_name)
    bucket = client.get_bucket(bucket_name)
    bucket.delete_object(file_key)
  end

  # marker为标记值，比如最后一次拿到的文件名是images/210910/kcxh6scpb.jpg，marker传该名可以继续往下拿数据
  def self.object_list(marker = nil, limit = 200)
    bucket_name = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun, :oss_bucket_name)
    bucket = client.get_bucket(bucket_name)
    bucket.list_objects(marker: marker).take(limit)
  end
end
