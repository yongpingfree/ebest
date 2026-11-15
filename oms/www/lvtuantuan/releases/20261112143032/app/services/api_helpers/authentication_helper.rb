# frozen_string_literal: true

module ApiHelpers
  module AuthenticationHelper
    def require_authentication?
      return false if options.dig(:route_options, :skip_authentication)

      !(request.path =~ /doc|examples/)
    end

    # Returns 401 response. To handle malformed / invalid requests.
    def unauthenticated!
      response_error "401 Unauthorized", 401
    end

    # Validates the token and user and sets the @current_user scope
    def authenticate!
      if !payload || !JsonWebToken.valid_payload(payload.first)
        return unauthenticated!
      end
      unauthenticated! unless current_user
    end

    # Sets the @current_user with the access_token from payload
    def current_user
      if payload.present? && payload[0]["certificate"]
        @current_user ||= MagicBean::User.registered.where(ebest_platform_unionid: payload[0]["certificate"])
          .or(MagicBean::User.registered.where(id: payload[0]["certificate"])).first
      else
        nil
      end
    end

    def current_store_id
      @current_store_id ||=
        if request.headers["Current-Store-Id"].present?
          request.headers["Current-Store-Id"].to_i
        else
          MagicBean::Store.default.first&.id
        end
    end

    def current_store_site_config
      @site_config ||= MagicBean::SiteConfig.find_by store_id: current_store_id
    end

    def current_store_time_zone
      current_store_site_config&.custom_time_zone || ApplicationRecord::TIME_ZONE
    end

    def current_postal_code
      request.headers["Current-Postal-Code"]
    end

    def current_suburb
      request.headers["Current-Suburb"]
    end

    def current_app_version
      request.headers["Current-App-Version"]
    end

    def current_delivery_area_id
      delivery_area_id = params[:delivery_area_id] || request.headers["Current-Delivery-Area-Id"]
      # 禁止定位时会出现delivery_area_id为0的情况
      if delivery_area_id.to_s == "0" || delivery_area_id.to_s == "undefined"
        MagicBean::DeliveryArea.find_by(suburb: "Sydney", postal_code: "2000")&.id
      else
        delivery_area_id
      end
    end

    def current_delivery_area
      @current_delivery_area ||= MagicBean::DeliveryArea.find_by(id: current_delivery_area_id) if current_delivery_area_id.present?
    end

    def search_delivery_types
      delivery_types = MagicBean::Item::DELIVERY_TYPE_ARRAY
      delivery_types -= [ "merchant_delivery"] unless current_delivery_area
      delivery_types
    end

    def default_avatar
      @default_avatar ||= MagicBean::SiteConfig.default_config.user_default_avatar
    end

    def check_api_authorization_token!
      unauthenticated! if request.headers["Api-Authorization-Token"] != Rails.application.credentials.dig(Rails.env.to_sym, :api_authorization_token)
    end

    def check_aus_api_authorization_token!
      unauthenticated! if request.headers["Api-Authorization-Token"] != Rails.application.credentials.dig(Rails.env.to_sym, :aus_api_authorization_token)
    end

    # https://trello.com/c/3RU3pU8y/316-8-更换omipay账号及微信登录流程
    # 微信登录用户成为会员的情况:
    # 1. 若手机已关联其他用户，且其他会员是已关联微信，则提示该号码已被绑定
    # 2. 若手机已关联其他用户，但其他会员是未关联微信，则将当前用户所有信息更新到旧用户上，删除当前用户(非会员无敏感数据)
    def check_member_mobile_authorization(member, app_channel = false)
      mobile_user = member.user

      # 当前用户与已绑该手机的用户不是同一个用户
      if current_user && mobile_user && current_user.id != mobile_user.id
        # 小程序上如果mobile_user的open_id不为空，即可认为已被绑定，因为用户一开始是根据open_id查找
        # 但手机用户不一样，如果当前用户曾使用微信A在小程序登录，open_id不为空，
        # 用户在app用微信A登录，绑定原手机，此时是无法区分app的微信是否跟小程序的微信一致，所以app用户需借助app_channel
        if mobile_user.ebest_platform_unionid? || (!app_channel && mobile_user.open_id?)
          response_error(I18n.t("grape.users.phone_number_taken"))
        else
          mobile_user.rebase_other_user(current_user)
        end
      end
    end

    # https://trello.com/c/3RU3pU8y/316-8-更换omipay账号及微信登录流程
    # 手机登录用户绑定微信情况
    # 1. 若用户已关联微信号，提示用户已绑定微信
    # 2. 若用户未关联微信号，且要绑定的微信号未绑定其他用户，则更新用户微信信息
    # 3. 若用户未关联微信号，但要绑定的微信号已绑定其他用户A，且A为会员，提示微信号已绑定其他会员账号
    # 4. 若用户未关联微信号，但要绑定的微信号已绑定其他用户A，A非会员，则将A所有信息更新到当前用户上，删除用户A
    def check_wechat_authorization(wechat_result)
      response_error(I18n.t("grape.users.already_bound_to_wechat")) if current_user.ebest_platform_unionid?
      user = MagicBean::User.find_by(ebest_platform_unionid: wechat_result["unionid"])

      if user
        response_error(I18n.t("grape.users.account_deleted"), 403) if user.deleted_by_user?
        response_error(I18n.t("grape.users.be_bound_to_another_member_account")) if user.member.present?
        current_user.rebase_other_user(user)
      else
        current_user.update!(
          ebest_platform_unionid: wechat_result["unionid"],
          nickname: wechat_result["nickname"],
          avatar: wechat_result["headimgurl"],
          gender: wechat_result["sex"],
          app_open_id: wechat_result["openid"]
        )
      end
    end

    # 1. 若unionid不存在用户或unionid跟用户unionid一致，则直接更新用户微信信息
    # 2. 若unionid存在其他用户A，若两个均无非会员，则合并用户A到当前用户
    # 3. 若unionid存在其他用户A，若其中一个为会员，则将非会员合并到会员用户
    # 4. 若unionid存在其他用户A，若两个均为会员，则将小程序member合并到app member, 并将小程序user合并到app user
    def mini_user_check_unionid(user, unionid, user_data)
      mobile_user = MagicBean::User.find_by(ebest_platform_unionid: unionid)

      if !mobile_user || mobile_user.id == user.id
        user.update(
          {
            ebest_platform_unionid: unionid,
            nickname: user_data["nickName"],
            avatar: user_data["avatarUrl"],
            gender: user_data["gender"],
          }
        )
      elsif mobile_user.member.blank?
        user.rebase_other_user(mobile_user)
      elsif user.member.blank?
        mobile_user.rebase_other_user(user)
      else
        mobile_user.member.rebase_other_member(user.member)
        mobile_user.rebase_other_user(user)
      end
    end

    private
    # Deconstructs the Authorization header and decodes the JWT token.
    def payload
      token = request.headers["Authorization"]
      JsonWebToken.decode(token)
    rescue
      nil
    end
  end
end
