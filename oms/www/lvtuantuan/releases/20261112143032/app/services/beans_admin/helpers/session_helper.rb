# frozen_string_literal: true

module BeansAdmin::Helpers
  module SessionHelper
    def require_authentication?
      !(request.path =~ /doc|examples/)
    end

    # Returns 401 response. To handle malformed / invalid requests.
    def unauthenticated!
      response_error "401 Unauthorized", 401
    end

    def user_session_key(user = nil)
      "user-#{(user || current_admin_user)&.id}-#{env["rack.session"]["session_id"]}"
    end

    def redis_session
      Rails.cache.redis.get(user_session_key)
    end

    # Validates the token and user and sets the @current_admin_user scope
    def authenticate!
      return if !require_authentication?
      unauthenticated! if env["rack.session"][:admin_user_id].blank? || redis_session.blank? ||
                          !env["rack.session"][:permissions].eql?(current_admin_user.permissions_md5) ||
                          current_admin_user&.banned?
    end

    def current_store_id
      request.headers["Store-Id"].to_i if request.headers["Store-Id"].present?
    end

    def current_admin_user
      return nil if env["rack.session"][:admin_user_id].blank?
      @current_admin_user ||= MagicBean::AdminUser.active.find(env["rack.session"][:admin_user_id])
    end
    alias current_user current_admin_user

    def sign_in_admin_user(admin_user)
      if admin_user && admin_user.active?
        # 把session_id 写到redis, 并设置过期时间
        Rails.cache.redis.set(user_session_key(admin_user), admin_user.id, ex: ApplicationRecord::ADMIN_LOGIN_SECOND.seconds)
        env["rack.session"][:admin_user_id] = admin_user.id
        env["rack.session"][:permissions] = admin_user.permissions_md5
      end
    end

    def sign_out_admin_user
      Rails.cache.redis.del(user_session_key)
      env["rack.session"][:admin_user_id] = nil
    end

    def default_avatar
      @default_avatar ||= MagicBean::SiteConfig.default_config.user_default_avatar
    end
  end
end
