
# frozen_string_literal: true

module FileUploadConcern
  extend ActiveSupport::Concern

  def aws_upload!(path)
    self.class.aws_upload!(path)
  end

  def aliyun_upload!(path)
    self.class.aliyun_upload!(path)
  end

  module ClassMethods
    def aliyun_upload!(path)
      aliyun_config = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun)
      bucket_name = aliyun_config[:oss_bucket_name]
      endpoint = aliyun_config[:oss_endpoint]
      region = aliyun_config[:oss_region]
      oss_cdn_host = aliyun_config[:oss_cdn_host]

      bucket = ::OSS.client.get_bucket(bucket_name)
      file_name = "images/qrcodes/#{Date.current.strftime("%y%m%d")}/#{SecureRandom.hex(5)[0..8]}.png"
      result = bucket.put_object(
        file_name,
        file: path
      )
      if result
        Rails.env.production? ? "https://#{oss_cdn_host}/#{file_name}" : "https://#{bucket_name}.#{endpoint}/#{file_name}"
      else
        raise "文件上传失败"
      end
    end

    def aws_upload!(path)
      aws_config = Rails.application.credentials.dig(Rails.env.to_sym, :aws)

      s3 = Aws::S3::Resource.new
      bucket = s3.bucket(aws_config[:bucket])
      key = "images/qrcodes/#{Date.current.strftime("%y%m%d")}/#{SecureRandom.hex(5)[0..8]}.png"

      obj = bucket.object(key)
      result = obj.upload_file(path, acl: "public-read")
      
      if result
        obj.public_url
      else
        raise "文件上传失败"
      end
    end
  end
end
