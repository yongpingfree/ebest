# frozen_string_literal: true

module Wechat
  class Api
    include HTTParty
    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ]
    HTTPARTY_TIMEOUT = 15
    RETRY_TIMES = 3
    QRCODE_PATH = File.join Rails.root, "public", "uploads", "qrcodes"
    RELATIVE_PATH = File.join "uploads", "qrcodes"

    base_uri "https://api.weixin.qq.com"

    @@logger = ::Logger.new("./log/wx_app_api.log")

    def self.code_to_session(code)
      tries = RETRY_TIMES
      wechat_account = Rails.application.credentials.dig(Rails.env.to_sym, :wechat)
      query = {
        appid: wechat_account[:app_id],
        secret: wechat_account[:app_secret],
        js_code: code,
        grant_type: "authorization_code"
      }
      response = HTTParty.get("https://api.weixin.qq.com/sns/jscode2session?#{query.to_query}", timeout: HTTPARTY_TIMEOUT)
      JSON.parse(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => _
      (tries -= 1) > 0 ? retry : { "errmsg" => "请求超时，请重试" }
    end

    def self.get_mini_program_qrcode(scene, path, width, return_binary = false, is_hyaline)

      body = {
        scene: scene,
        width: width || 260,
        is_hyaline: is_hyaline || false
      }

      # page 必须是已经发布的小程序存在的页面（否则报错）
      body[:page] = path if Rails.env.production?

      result = wx_app_post(wx_qrcode_url, body: body)

      if result.body.present? && !result.body.include?("errcode")
        if return_binary
          file = result.body
        else
          file_name = Digest::MD5.hexdigest(body.values.join("")).concat(".jpg")
          dir = File.dirname("#{QRCODE_PATH}/#{file_name}")
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          File.open(File.join(QRCODE_PATH, file_name), "wb") { |f| f.write(result.body) }
          file = "#{ Rails.application.credentials.dig(Rails.env.to_sym, :domain) }/#{ File.join(RELATIVE_PATH, file_name) }"
        end
         { status: "success",  file: file }
      else
        return { status: "error", message: "生成二维码失败, 请重试！" }
      end
    end

    def self.msg_sec_check(content)
      body = {
        content: content
      }
      wx_app_post("/wxa/msg_sec_check", body: body)
    end

    def self.wx_app_post(path, options = {}, need_access_token = true)
      tries = RETRY_TIMES
      body = (options[:body] || {})
      headers = (options[:headers] || {}).reverse_merge({
        "Content-Type" => "application/json"
      })
      path = "#{path}?access_token=#{Wechat::AccessToken.get_mini_program_access_token}" if need_access_token

      @@logger.debug("request: method: post, url: #{path}, body: #{body}, headers: #{headers}")
      response = begin
                   post(path, body: JSON.pretty_generate(body), headers: headers, timeout: HTTPARTY_TIMEOUT)
                 rescue *HTTP_ERRORS => error
                   (tries -= 1) > 0 ? retry : { "msg" => "连接超时" }
                 rescue StandardError => error
                    # 偶尔出现 undefined method body for nil
                   (tries -= 1) > 0 ? retry : {"msg" => "其他错误"}
                 end
      @@logger.debug("response: #{response}")
      response
    end

    def self.wx_qrcode_url
      "/wxa/getwxacodeunlimit"
    end

    # [{
    #    "ref_date"=>"20180713",
    #    "session_cnt"=>39,
    #    "visit_pv"=>142,
    #    "visit_uv"=>12,
    #    "visit_uv_new"=>1,
    #    "stay_time_uv"=>202.8333,
    #    "stay_time_session"=>62.4103,
    #    "visit_depth"=>2.0256
    # }]
    def self.get_weanalysis_appid_daily_visit_trend(begin_date, end_date)
      (begin_date..end_date).map do |date|
        if %w[staging production].include?(Rails.env)
          data_in_redis = Analyses::Cache.get("getweanalysisappiddailyvisittrend", date)
          if data_in_redis
            ActiveSupport::JSON.decode(data_in_redis)
          elsif date < Date.current
            result = wx_app_post("/datacube/getweanalysisappiddailyvisittrend", body: { begin_date: date, end_date: date })
            next if result["errcode"]

            object = result["list"][0]

            Analyses::Cache.set("getweanalysisappiddailyvisittrend", date, object.to_json)
            object
          end
        end
      end
    end

    # https://developers.weixin.qq.com/miniprogram/dev/api-backend/open-api/subscribe-message/subscribeMessage.send.html
    # options = {
    #   touser: openid,
    #   template_id: template_id,
    #   data: data,
    #   page: page
    # }
    def self.send_subscribe_template(options)
      options.merge!({
        page: options.delete(:page) || "pages/tabbar/home/home",
        data: Wechat::TemplateMessage.data_formater(options.delete(:data))
      })
      wx_app_post("/cgi-bin/message/subscribe/send", body: options)
    end
  end
end
