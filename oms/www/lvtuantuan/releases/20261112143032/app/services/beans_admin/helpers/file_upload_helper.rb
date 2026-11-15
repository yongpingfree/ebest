# frozen_string_literal: true

module BeansAdmin::Helpers
  module FileUploadHelper
    def check_file_type(file, target_type)
      case target_type
      when "xlsx"
        file["type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      when "csv"
        file["type"] == "text/csv"
      end
    end

    def aliyun_upload!(local_file_path, remote_file_name)
      aliyun_config = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun)
      bucket_name = aliyun_config[:oss_bucket_name]
      endpoint = aliyun_config[:oss_endpoint]
      region = aliyun_config[:oss_region]
      oss_cdn_host = aliyun_config[:oss_cdn_host]
      bucket = ::OSS.client.get_bucket(bucket_name)

      result = bucket.put_object(
        remote_file_name,
        file: local_file_path
      )

      if result
        Rails.env.production? ? "https://#{oss_cdn_host}/#{remote_file_name}" : "https://#{bucket_name}.#{endpoint}/#{remote_file_name}"
      else
        raise "文件上传失败"
      end
    end

    def aws_upload!(local_file_path, remote_file_name)
      aws_config = Rails.application.credentials.dig(Rails.env.to_sym, :aws)

      s3 = Aws::S3::Resource.new
      bucket = s3.bucket(aws_config[:bucket])

      obj = bucket.object(remote_file_name)
      result = obj.upload_file(local_file_path, acl: "public-read")
      
      if result
        obj.public_url
      else
        raise "文件上传失败"
      end
    end
  end
end
