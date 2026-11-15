# frozen_string_literal: true

module ApiHelpers
  module SharedParamsHelper
    extend Grape::API::Helpers

    params :created_at_search do
      optional :created_at_gteq_datetime, type: DateTime, desc: "创建时间大于或等于"
      optional :created_at_lteq_datetime, type: DateTime, desc: "创建时间小于或等于"
    end

    params :sign_params do
      optional :sign, type: String, desc: "签名", documentation: { param_type: "query" }
      optional :timestamp, type: String, desc: "时间戳", documentation: { param_type: "query" }
      optional :skip_authenticate, type: Grape::API::Boolean, desc: "测试可跳过签名", default: "false"
    end
  end
end
