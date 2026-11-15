# frozen_string_literal: true

Qiniu.establish_connection! Rails.application.credentials.dig(Rails.env.to_sym, :qiniu).symbolize_keys
