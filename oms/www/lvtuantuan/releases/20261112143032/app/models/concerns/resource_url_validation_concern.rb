# frozen_string_literal: true

# 图片/图标字段限定白名单 host，防止存储型 SSRF
# （服务端拉图链路：GenerateAwsLambdaImageJob / Aliexpress::ImageBank）
# 模型定义 RESOURCE_URL_COLUMNS 生效；Item/SKU 覆盖
# resource_url_validation_enabled? 豁免 ae_drop_shipper，
# 豁免条件与 GenerateAwsLambdaImageJob 的跳过条件保持一致（其图片来自速卖通 CDN）
module ResourceUrlValidationConcern
  extend ActiveSupport::Concern

  included do
    validate :validate_resource_url_hosts, if: -> { resource_url_validation_enabled? && resource_url_columns_changed? }
  end

  def resource_url_validation_enabled?
    true
  end

  private

  def validate_resource_url_hosts
    resource_url_columns.each do |column|
      values = [*public_send(column)].flatten.compact
      next if values.blank?
      unless Validators::ResourceUrl.valid?(values)
        errors.add(column, "无效链接")
      end
    end
  end

  def resource_url_columns
    self.class::RESOURCE_URL_COLUMNS
  end

  def resource_url_columns_changed?
    (changes_to_save.keys & resource_url_columns.map(&:to_s)).present?
  end
end
