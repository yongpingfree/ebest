# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "elasticsearch/transport"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EcommerceBackendBase
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    #set default locale file
    config.i18n.default_locale = "zh-CN"
    config.i18n.available_locales = [:"zh-CN", :"zh-TW", :en]

    config.active_record.default_timezone = :local
    config.time_zone = "Melbourne"

    config.paths.add "lib", eager_load: true, autoload: true
    config.paths.add File.join("app", "services"), glob: File.join("**", "*.rb"), eager_load: false, autoload: true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.middleware.use Rack::Attack
    config.middleware.insert_before 0, Rack::Cors, debug: true, logger: (-> { Rails.logger }) do
      allow do
        origins "*"
        resource "*",
          headers: :any,
          methods: [:get, :post, :delete, :put, :options, :head, :patch],
          expose: %w[x-total x-total-pages x-offset x-page x-per-page x-prev-page x-next-page],
          max_age: 0
      end
    end

    config.active_job.queue_adapter = :sidekiq

    # Defaults to `redis://localhost:6379/0`
    redis_config = Rails.application.credentials.dig(Rails.env.to_sym, :redis)
    redis_server = redis_config[:redis_server]
    redis_port = redis_config[:redis_port]
    redis_db_num = redis_config[:redis_db_num]
    config.cache_store = :redis_cache_store, { url: "redis://#{redis_server}:#{redis_port}/#{redis_db_num}" }

    config.action_mailer.asset_host = Rails.application.credentials.dig(Rails.env.to_sym, :domain)
  end
end
