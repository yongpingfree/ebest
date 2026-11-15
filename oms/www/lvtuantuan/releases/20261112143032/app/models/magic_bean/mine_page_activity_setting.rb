# frozen_string_literal: true
class MagicBean::MinePageActivitySetting < ApplicationRecord
  belongs_to :custom_page, optional: true
  belongs_to :store

  translates :name
  globalize_accessors attributes: [:name]

  validates :name_zh_cn, :icon, presence: true
  
  validate :check_enabled_settings_count

  before_create :set_name_i18n

  def path_name
    JSON.parse(path)["name"] if path.present?
  rescue JSON::ParserError
    nil
  end

  private

  # 最多只能同时设置5个生效的配置
  def check_enabled_settings_count
    if enabled && self.class.where(store_id: store_id, enabled: true).where.not(id: id).count >= 5
      errors.add(:base, "最多只能同时设置5个生效的配置")
    end
  end

  def set_name_i18n
    self.name_zh_tw = Ropencc.conv("s2tw.json", name_zh_cn) if name_zh_tw.blank?
    self.name_en = EasyTranslate.translate(name_zh_cn, from: :"zh-CN", to: :en) if name_en.blank?
  end
end
