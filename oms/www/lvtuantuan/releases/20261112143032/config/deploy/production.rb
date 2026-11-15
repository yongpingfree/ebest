# frozen_string_literal: true

server "3.24.0.60", user: "deploy", roles: %w{app db web}
server "13.54.78.68", user: "deploy", roles: %w{app db web}
server "13.238.48.203", user: "deploy", roles: %w{app db web}
set :app_url, "https://minimall.donkibuy.com"
set :user, "deploy"
set :rvm_ruby_version, "2.5.7"
set :rails_env, "production"
set :branch, "master"
set :puma_workers, 2
set :puma_bind, "tcp://0.0.0.0:8080"
