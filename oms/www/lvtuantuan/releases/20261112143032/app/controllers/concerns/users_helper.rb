# frozen_string_literal: true

module UsersHelper
  def current_user
    @current_user ||=
      if certificate
        MagicBean::User.registered.where(ebest_platform_unionid: certificate.to_s)
          .or(MagicBean::User.registered.where(id: certificate))
          .first
      else
        MagicBean::User.registered.find_by(id: user_id)
      end
  end

  def user_id
    session[:user_id] if session
  end

  def certificate
    payload["certificate"] if payload
  end

  def payload
    token = request.headers["Authorization"] || params[:authorization]
    ActiveSupport::HashWithIndifferentAccess.new(
      JsonWebToken.decode(token)[0]
    )
  rescue
    nil
  end
end
