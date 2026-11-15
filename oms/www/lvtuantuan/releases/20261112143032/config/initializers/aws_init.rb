# frozen_string_literal: true

AWS_SETTING = Rails.application.credentials.dig(Rails.env.to_sym, :aws)
AWS_CDN_HOST, AWS_THUMBNAIL_PREFIX_PATH = AWS_SETTING[:cdn_host], AWS_SETTING[:thumbnail_prefix_path]

Aws.config.update({
  region: AWS_SETTING[:region],
  credentials: Aws::Credentials.new(AWS_SETTING[:app_key], AWS_SETTING[:app_secret])
})
