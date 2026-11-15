# frozen_string_literal: true
module MagicBean
  class EmailVerificationCode
    EXPIRATION = 15.minutes
    SEND_INTERVAL = 1.minute
    STAGING_TEST_VERIFICATION_CODE = "87654321"
    include Redis::Objects

    attr_reader :email, :event

    value :code_in_redis, expiration: EXPIRATION
    value :sent_at, expiration: EXPIRATION, marshal: true

    MESSAGE = {
      login: "登录",
      overseas_student_auth: "留学生身份认证",
      bind_member: "会员绑定邮箱",
      shopline_signup: "Shopline注册",
      shopline_reset_email: 'Shopline修改邮箱',
      shopline_new_email: 'Shopline新邮箱验证',
      shopline_reset_password: 'Shopline重置密码',
      shopline_reset_phone: 'Shopline修改手机号', # 修改手机号也会用到邮箱验证码
    }

    def initialize(email, event)
      @email = email&.downcase
      @event = event
    end

    def send_code
      new_code = generate_new_code
      self.code = new_code
      sent_at.set(Time.current)

      message = "【eBest】Your verification code is #{code}"
      OverseasStudentMailer.notify(email, message, "【eBest】email verification code").deliver_later
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
      "#{email}_#{event}"
    end

    def verify(params_code)
      return true if params_code.to_s == STAGING_TEST_VERIFICATION_CODE && !Rails.env.production?
      params_code.to_s == code.to_s
    end

    private
    def generate_new_code(len = 6)
      chars = ("0".."9").to_a
      len.times.map { chars.sample }.join
    end

    class << self
      def verify(email, event, params_code)
        new(email, event).verify(params_code)
      end

      MESSAGE.keys.each do |event|
        define_method "build_#{event}_object" do |email|
          new(email, event)
        end
      end
    end
  end
end
