# frozen_string_literal: true
require "rest-client"

class NotifyAccessTokenJob < ApplicationJob
  queue_as :default

  def perform
    url = Rails.application.credentials.dig(Rails.env.to_sym, :wechat, :access_token_notify_url)
    access_token = Wechat::AccessToken.get_mini_program_access_token

    RestClient.post(url, access_token: access_token) if url && access_token
  end
end
