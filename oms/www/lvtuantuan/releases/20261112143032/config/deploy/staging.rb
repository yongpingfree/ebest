# frozen_string_literal: true

server "13.237.72.23", user: "deploy", roles: %w{app db web}

set :app_url, "https://ebest.beansmile-dev.com"
set :user, "deploy"
set :rvm_ruby_version, "2.5.7"
set :rails_env, "staging"
set :branch, "develop"
set :puma_workers, 1
