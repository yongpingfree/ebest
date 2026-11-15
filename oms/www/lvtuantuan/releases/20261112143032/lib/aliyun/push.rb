# frozen_string_literal: true
require "openssl"
require "base64"
require "erb"
require "net/https"
require "json"
include ERB::Util

# The AliyunPush 阿里云 app 推送接口封装
module Aliyun::Push
  @@logger = ::Logger.new("./log/aliyun_push.log")
  ALIYUN_CONFIG = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun_push)

  # The Configuration 配置类
  class Configuration
    attr_accessor :access_key_secret, :access_key_id, :format, :region_id,
                  :version, :signature_method, :signature_version, :domain, :android_app_key, :ios_app_key
    def initialize
      @format = "JSON"
      @region_id = "cn-shanghai"
      @version = "2016-08-01"
      @signature_method = "HMAC-SHA1"
      @signature_version = "1.0"
      @domain = "cloudpush.aliyuncs.com"
      @access_key_secret ||= ALIYUN_CONFIG[:access_key_secret]
      @access_key_id ||= ALIYUN_CONFIG[:access_key_id]
      @android_app_key ||= ALIYUN_CONFIG[:android_app_key]
      @ios_app_key ||= ALIYUN_CONFIG[:ios_app_key]
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def get_response(api_params)
      public_params ={
        "Format" => configuration.format,
        "RegionId" => configuration.region_id,
        "Version" => configuration.version,
        "AccessKeyId" => configuration.access_key_id,
        "SignatureMethod" => configuration.signature_method,
        "Timestamp" => seed_timestamp,
        "SignatureVersion" => configuration.signature_version,
        "SignatureNonce" => seed_signature_nonce
      }
      public_params = public_params.merge api_params
      public_params["Signature"] = sign configuration.access_key_secret, public_params
      @@logger.info("Request params: #{public_params}")
      response = send_request(public_params).body
      @@logger.info("Response body: #{response}")
      JSON.parse(response)
    end

    # 原生参数经过2次编码拼接成标准字符串
    def canonicalized_query_string(params)
      cqstring = ""

      # Canonicalized Query String / 使用请求参数构造规范化的请求字符串
      # 按照参数名称的字典顺序对请求中所有的请求参数进行排序
      params = params.sort.to_h
      params.each do |key, value|
        if cqstring.empty?
          cqstring += url_encode"#{key}=#{url_encode(value)}"
        else
          cqstring += url_encode"&#{key}=#{url_encode(value)}"
        end
      end

      cqstring
    end

    # 生成数字签名
    def sign(key_secret, params)
      key = key_secret + "&"
      signature = "POST" + "&" + url_encode("/") + "&" + canonicalized_query_string(params)
      digest = OpenSSL::Digest.new("sha1")
      sign = Base64.encode64(OpenSSL::HMAC.digest(digest, key, signature))
      sign.chomp # 通过chomp去掉最后的换行符 LF
    end

    # 生成短信时间戳
    def seed_timestamp
      Time.now.utc.strftime("%FT%TZ")
    end

    # 生成短信唯一标识码，采用到微秒的时间戳
    def seed_signature_nonce
      Time.now.utc.strftime("%Y%m%d%H%M%S%L")
    end

    def send_request(params)
      uri = URI("https://" + configuration.domain)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new uri
        request.set_form_data params
        http.request request # Net::HTTPResponse object
      end
    end

    # 推通知给 Android 设备
    # https://help.aliyun.com/document_detail/71974.html?spm=a2c4g.11186623.2.16.56424c07IWrLtL
    def push_notice_to_android(target, target_value, title, body, ext_parameters = nil)
      api_params = {
        "Action" => "Push",
        "AppKey" => configuration.public_send("android_app_key"),
        "Target" => target,
        "TargetValue" => target_value,
        "Title" => title,
        "Body" => body,
        "DeviceType" => "ANDROID",
        "PushType" => "NOTICE",
        "AndroidExtParameters" => ext_parameters,
        "StoreOffline" => true,
        "AndroidNotificationChannel" => "1", # 移动端集成时对应的channel值，为了支持android 8.0, ref:https://help.aliyun.com/knowledge_detail/67398.html
        # [Android端辅助通道推送限制](https://help.aliyun.com/document_detail/165253.html?spm=a2c4g.11186623.2.15.5eebd8c21ZMmXe)
        "AndroidPopupActivity" => "org.wonday.aliyun.push.ThirdPartMessageActivity",
        "AndroidPopupTitle" => title.truncate(30),
        "AndroidPopupBody" => body.truncate(128)
      }
      get_response api_params
    end

    # 推通知给 iOS 设备
    def push_notice_to_ios(target, target_value, title, body, ext_parameters = nil)
      api_params = {
        "Action" => "PushNoticeToiOS",
        "AppKey" => configuration.public_send("ios_app_key"),
        "Target" => target,
        "TargetValue" => target_value,
        "ApnsEnv" => "PRODUCT",
        "Title" => title,
        "Body" => body
      }
      api_params["ExtParameters"] = ext_parameters if ext_parameters.present?
      get_response api_params
    end

    # 通过账户查询设备列表
    def query_devices_by_account(account, app_os)
      api_params = {
        "Action" => "QueryDevicesByAccount",
        "AppKey" => configuration.public_send("#{app_os}_app_key"),
        "Account" => account
      }

      get_response api_params
    end

    def push_notice_to(*args)
      push_notice_to_android(*args)
      push_notice_to_ios(*args)
    end
  end
end
