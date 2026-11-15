# frozen_string_literal: true

EasyTranslate.api_key = Rails.application.credentials.dig(:google, :translation, :api_key)
