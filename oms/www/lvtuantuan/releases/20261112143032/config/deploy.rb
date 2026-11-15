# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "lvtuantuan"
set :repo_url, "ssh://git@g.donkibuy.com:20022/ebest/oms.git"

# config for sidekiq
set :init_system, :systemd
set :sidekiq_config, "config/sidekiq.yml"
set :service_unit_name, "lvtuantuan-sidekiq.service"
set :rvm_custom_path, "/usr/share/rvm"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/lvtuantuan"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# set default stage as +staging+
set :stage, :staging

# Default value for :log_level is :debug
# set :log_level, :debug
set :log_level, :info

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/master.key", "config/database.yml", "config/apiclient_cert.p12", "public/BI6EwQhHQR.txt", "config/apple_pay_private_key.pem", "config/apple_pay_cert.pem", "config/apple_pay_merchant_cert.pem", "config/apple_pay_merchant_key.pem"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "public/uploads", "public/dist"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :deploy do
  desc "Initialize configuration using example files provided in the distribution"
  task :upload_config do
    on release_roles :all do |host|
      Dir["config/master.key", "config/*.yml.example"].each do |file|
        save_to = "#{shared_path}/config/#{File.basename(file, '.example')}"
        unless test "[ -f #{save_to} ]"
          upload!(File.expand_path(file), save_to)
        end
      end
    end
  end
  before "deploy:check:linked_files", "deploy:upload_config"

  desc "build admin frontend"
  task :build_frontend do
    on release_roles :all do
      within release_path do
        execute "cd #{release_path}/ecommerce-admin && yarn && NODE_ENV=#{fetch(:rails_env)} yarn build"
        execute "cp -r #{release_path}/ecommerce-admin/dist/admin #{release_path}/public/"
      end
    end
  end

  # after :updating, :build_frontend

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
      # execute "service nginx restart"
      invoke "puma:restart"
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc "Visit the app"
  task :visit_web do
    system "open #{fetch(:app_url)}"
  end

  after :deploy, "deploy:visit_web"
end

namespace :remote do
  desc "run rake task, usage: `cap staging remote:rake task='db:create'` "
  task :rake do
    on primary(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "run `rake #{ENV['task']}`"
          # inspired by https://github.com/capistrano/capistrano/issues/807
          execute :rake, ENV["task"]
        end
      end
    end
  end

  desc "run rake task, usage: `cap staging remote:run command='pwd'` "
  task :run do
    on primary(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          info "run `run command='your-command'`"
          # inspired by https://github.com/capistrano/capistrano/issues/807
          execute ENV["command"]
        end
      end
    end
  end

  desc "tail rails logs, usage: `cap staging remote:tail_log file=unicorn`"
  task :tail_log do
    on roles(:app) do
      with_verbosity Logger::DEBUG do
        log_file = ENV["file"] || fetch(:rails_env)
        execute "tail -f #{current_path}/log/#{log_file}.log"
      end
    end
  end

  # available output verbosity: ['Logger::DEBUG' 'Logger::INFO' 'Logger::ERROR' 'Logger::WARN']
  def with_verbosity(output_verbosity)
    old_verbosity = SSHKit.config.output_verbosity
    begin
      SSHKit.config.output_verbosity = output_verbosity
      yield
    ensure
      SSHKit.config.output_verbosity = old_verbosity
    end
  end
end
