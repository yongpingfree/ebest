# frozen_string_literal: true

class WechatAccessTokenJob < ApplicationJob
  queue_as :default

  def perform
    if Rails.env.production?
      begin
        Wechat::AccessToken.refresh_mini_program_access_token
        WechatAus::AccessToken.refresh_mini_program_access_token
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
         Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        retry_job wait: 5
      end
    end
  end
end
