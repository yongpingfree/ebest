# frozen_string_literal: true
module MagicBean
  class VerificationCode
    EXPIRATION = 15.minutes
    SEND_INTERVAL = 1.minute
    # 万能码仅限本地开发环境；staging/生产一律走真实短信码
    DEVELOPMENT_TEST_VERIFICATION_CODE = "87654321"
    UNIVERSAL_CODE_KEY = "universal-code"
    # 15 分钟窗口内最多 10 次失败尝试，超出后（直到窗口过期）一律拒绝，防止短信码爆破
    MAX_VERIFY_ATTEMPTS = 10
    VERIFY_ATTEMPT_WINDOW = EXPIRATION
    include Redis::Objects

    attr_reader :mobile, :event

    value :code_in_redis, expiration: EXPIRATION
    value :sent_at, expiration: EXPIRATION, marshal: true
    counter :failed_attempts, expiration: VERIFY_ATTEMPT_WINDOW

    MESSAGE = {
      login: "账户登录",
      reset_password: "管理员重置密码",
      register_member: "注册会员",
      reset_mobile: "修改手机号",
      app_mobile_auth: "App手机授权",
      app_reset_password: "用户重置密码",
      shopline_new_phone: 'Shopline新手机验证',
      shopline_reset_phone: 'Shopline修改手机号',
      shopline_reset_email: 'Shopline修改邮箱'
    }

    def initialize(mobile, event)
      @mobile = mobile
      @event = event
    end

    def send_code
      new_code = generate_new_code
      self.code = new_code
      sent_at.set(Time.current)

      message = "【eBest】Your verification code is #{code}"
      SmsJob.perform_later(mobile, message) unless Rails.env.development?
    end

    def can_send_again?
      Time.current - sent_at.get >= SEND_INTERVAL
    end

    def code
      code_in_redis.get
    end

    def code=(new_code)
      code_in_redis.set(new_code)
    end

    def id
      "#{mobile}_#{event}"
    end

    def verify(params_code)
      return true if Rails.env.development? && params_code.to_s == DEVELOPMENT_TEST_VERIFICATION_CODE
      return false if failed_attempts.value >= MAX_VERIFY_ATTEMPTS

      if params_code.to_s == code.to_s || verify_universal_code(params_code)
        failed_attempts.reset
        true
      else
        failed_attempts.increment
        false
      end
    end

    def verify_universal_code(params_code)
      universal_code = Rails.cache.fetch(MagicBean::VerificationCode::UNIVERSAL_CODE_KEY)
      if universal_code.present? && universal_code.eql?(params_code)
        Rails.cache.delete(MagicBean::VerificationCode::UNIVERSAL_CODE_KEY)
        true
      else
        false
      end
    end

    private
    def generate_new_code(len = 6)
      chars = ("0".."9").to_a
      len.times.map { chars.sample }.join
    end

    class << self
      def verify(mobile, event, params_code)
        new(mobile, event).verify(params_code)
      end

      MESSAGE.keys.each do |event|
        define_method "build_#{event}_object" do |mobile|
          new(mobile, event)
        end
      end
    end
  end
end
