# frozen_string_literal: true
module Aliyun
  class CustomOss
    aliyun_config = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun)

    ACCESS_KEY_ID = aliyun_config[:access_key_id]
    ACCESS_KEY_SECRET = aliyun_config[:secret_access_key]
    BUCKET = aliyun_config[:oss_bucket_name]
    ENDPOINT = aliyun_config[:oss_endpoint]
    OSS_HOST = Rails.env.production? ? aliyun_config[:oss_cdn_host] : "#{BUCKET}.#{ENDPOINT}"
    HOST = "https://#{OSS_HOST}"
    DIR = "images/"
    EXPIRY = 60.seconds

    def self.signature
      expiration = Time.now + EXPIRY
      policy = {
        "expiration" => expiration.utc.iso8601.sub("Z", ".000Z"),
        "conditions" => [
          ["eq", "$bucket", BUCKET],
          ["starts-with", "$key", DIR]
        ]
      }
      policy_string = Base64.strict_encode64(policy.to_json)

      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest(
          "sha1",
          ACCESS_KEY_SECRET,
          policy_string
        )
      )

      {
        access_key_id: ACCESS_KEY_ID,
        host: HOST,
        policy: policy_string,
        signature: signature,
        expire: expiration,
        dir: DIR,
        watermark_serialized: MagicBean::SiteConfig.default_config&.watermark_serialized
      }
    end

    # https://help.aliyun.com/document_detail/31988.htm?spm=a2c4g.11186623.0.0.72fa125483gU90#reference-smp-nsw-wdb
    def self.safe_signature(params)
      # 校验文件名是否存在，如果已存在的话，不允许上传
      client = Aliyun::OSS::Client.new(
        endpoint: ENDPOINT,
        access_key_id: ACCESS_KEY_ID,
        access_key_secret: ACCESS_KEY_SECRET
      )

      object_name = "#{DIR}#{params[:key]}"
      bucket = client.get_bucket(BUCKET)

      return { error: I18n.t("grape.aliyun_oss.file_exists") } if client.bucket_exist?(BUCKET) && bucket.object_exist?(object_name)

      expiration = Time.now + EXPIRY
      policy = {
        "expiration" => expiration.utc.iso8601.sub("Z", ".000Z"),
        "conditions" => [
          ["content-length-range", params[:content_length] - 10,  params[:content_length] + 10],
          ["eq", "$bucket", BUCKET],
          ["eq", "$key", object_name],
          ["eq", "$x-oss-meta-biedb", params[:meta_biedb]]
        ]
      }
      policy_string = Base64.strict_encode64(policy.to_json)

      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest(
          "sha1",
          ACCESS_KEY_SECRET,
          policy_string
        )
      )

      {
        access_key_id: ACCESS_KEY_ID,
        host: HOST,
        policy: policy_string,
        signature: signature,
        expire: expiration,
        dir: DIR,
        watermark_serialized: MagicBean::SiteConfig.default_config&.watermark_serialized
      }
    end
  end
end
