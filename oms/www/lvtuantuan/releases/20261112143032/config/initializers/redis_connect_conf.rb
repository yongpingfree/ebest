# frozen_string_literal: true

redis_config = Rails.application.credentials.dig(Rails.env.to_sym, :redis)
redis_server = redis_config[:redis_server]
redis_port = redis_config[:redis_port]
redis_db_num = redis_config[:redis_db_num]

redis_url = "redis://#{redis_server}:#{redis_port}/#{redis_db_num}"

RedisClient = Redis.new(
  host: redis_server,
  port: redis_port,
  db: redis_db_num
)

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

Redis::Objects.redis = Redis.new(url: redis_url)
