# frozen_string_literal: true

class AccessTokensController < ApplicationController
  skip_before_action :verify_authenticity_token

  # TODO: 等部署production后再移除, 否则会导致production抛错误异常
  def notify
    access_token = params[:access_token]

    Rails.cache.write "mini_program_access_token", access_token

    head :no_content
  end
end
