# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

rackapp = Rack::Builder.app do
  use Prometheus::Middleware::Collector

  map "/metrics" do
    use Rack::Auth::Basic, "Prometheus Metrics" do |username, password|
      Rack::Utils.secure_compare(Rails.application.credentials
        .dig(Rails.env.to_sym, :prometheus, :username), username) &&
      Rack::Utils.secure_compare(Rails.application.credentials
        .dig(Rails.env.to_sym, :prometheus, :password), password)
    end
    use Rack::Deflater
    use Prometheus::Middleware::Exporter, path: ""
    run ->(_) { [500, { "Content-Type" => "text/html" }, ["Weizhan metrics endpoint is unreachable!"]] }
  end

  run Rails.application
end

run rackapp
