# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
# Rails 按「子串」匹配参数名（:code 会过滤 verification_code / wechat 的 code 等）。
# 验证码、微信 code、支付回调里的 token/secret/卡号此前全部明文落日志。
Rails.application.config.filter_parameters += [
  :password,
  :code, :token, :secret, :api_key, :authorization,
  :card_number, :cvv, :cvc, :bank_account
]
