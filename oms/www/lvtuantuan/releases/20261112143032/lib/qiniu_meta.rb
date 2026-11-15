# frozen_string_literal: true

module QiniuMeta
  BUCKET = Qiniu::Config.settings[:bucket]
  DOMAIN = Qiniu::Config.settings[:domain]
  # 自定义响应内容：https://developer.qiniu.com/kodo/manual/1654/response-body
  RETURN_BODY_TEMPLATE = %Q[{"key":$(key),"hash":$(hash),"w":$(imageInfo.width),"h":$(imageInfo.height)}]
  EXPIRES_IN = 3600

  def self.generate
    put_policy = Qiniu::Auth::PutPolicy.new(
      BUCKET,
      nil,
      EXPIRES_IN
    )
    put_policy.return_body = RETURN_BODY_TEMPLATE

    uptoken = Qiniu::Auth.generate_uptoken(put_policy)

    {
      token: uptoken,
      bucket_domain: DOMAIN,
      expires_in: EXPIRES_IN,
      bucket: BUCKET
    }
  end
end
