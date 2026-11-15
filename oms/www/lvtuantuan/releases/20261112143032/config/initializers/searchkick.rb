# frozen_string_literal: true

# 使用阿里云的Elasticsearch服务，初始化配置
aliyun_es_config = Rails.application.credentials.dig(Rails.env.to_sym, :aliyun_elasticsearch)
Searchkick.client = Elasticsearch::Client.new(
  host: aliyun_es_config[:host],
  user: aliyun_es_config[:user],
  password: aliyun_es_config[:password],
  retry_on_failure: true,
  reload_on_failure: true,
  transport_options: { request: { timeout: 250 } },
  log: true
)

# test环境不使用ES
Searchkick.disable_callbacks unless Rails.env.production?
