# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from ActionController::UnknownFormat, with: :raise_unsupported_media_type

  def render_json_error(message, status_code = :bad_request)
    render(json: { error_message: message }, status: status_code)
  end

  def render_json_success(message, status_code = 200)
    render(json: { message: message }, status: status_code)
  end

  def raise_unsupported_media_type
    render(plain: "Unsupported media type", status: :unsupported_media_type)
  end
end
