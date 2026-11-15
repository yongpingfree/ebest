# frozen_string_literal: true

BLOCK_MESSAGE = ["你请求过快，超过了频率限制，暂时屏蔽一段时间。"]
RACK_ATTACK_LIMIT = MagicBean::SiteConfig.find_by(key: "rack_attack_limit")&.to_i || 300 rescue 300
RACK_ATTACK_PERIOD = MagicBean::SiteConfig.find_by(key: "rack_attack_period")&.to_i || 180 rescue 180
RACK_ATTACK_BLACKLIST_IPS = MagicBean::SiteConfig.find_by(key: "rack_attack_blacklist_ips") || "" rescue ""

class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Spammy Clients ###
  throttle("req/ip", limit: RACK_ATTACK_LIMIT, period: RACK_ATTACK_PERIOD, &:ip)

  # 固定黑名单
  blocklist("blacklist/ip") do |req|
    !RACK_ATTACK_BLACKLIST_IPS.index(req.ip).nil?
  end

  # 允许 localhost
  safelist("allow from localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### Custom Throttle Response ###
  self.throttled_response = lambda do |_env|
    [503, {}, BLOCK_MESSAGE]
  end
end

ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, request_id, req|
  Rails.logger.info "  RackAttack: #{req.ip} #{request_id} blocked."
end
