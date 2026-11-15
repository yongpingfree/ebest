# frozen_string_literal: true

module Validators
  class ResourceUrl < Grape::Validations::Base
    HOST_ARRAY = [
      "cdn.minimall.donkibuy.com",
      "lvtuantuan-staging.oss-ap-southeast-2.aliyuncs.com",
      "lvtuantuan-staging.s3.ap-southeast-2.amazonaws.com"
    ].freeze

    # 远程文件导入（CSV/XLSX）的合法来源：管理端 aws_upload!/aliyun_upload! 产出的存储 host。
    # 导入链拿到的是 obj.public_url（S3 直连域，不走 CDN 域名），故比图片白名单多 prod S3 域
    FILE_HOST_ARRAY = (HOST_ARRAY + ["ebest-production.s3.ap-southeast-2.amazonaws.com"]).freeze

    # nil/空串放行（拉取侧对 blank 也是跳过），数组自动展开，URI 解析失败视为无效
    def self.valid?(value)
      [*value].all? { |v| v.blank? || URI.parse(v).host.to_s.downcase.in?(HOST_ARRAY) }
    rescue URI::Error
      false
    end

    # 文件地址必须带 host 且在白名单内。与图片校验不同：blank 不放行（导入必须给地址），
    # file:// 等无 host 的 URL 一律拒绝
    def self.valid_file_url?(value)
      host = URI.parse(value.to_s).host.to_s.downcase
      host.present? && host.in?(FILE_HOST_ARRAY)
    rescue URI::Error
      false
    end

    def validate_param!(attr_name, params)
      values = [*params[attr_name]].reject(&:blank?)
      if values.present? && !self.class.valid?(values)
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "无效链接"
      end
    end
  end
end
