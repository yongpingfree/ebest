# frozen_string_literal: true

class MagicBean::Address < ApplicationRecord

  # scope

  # constants
  ENG_ADDRESS_REGEX = /\A[[:ascii:]]+\z/ # 考虑地址可能井号#、逗号, 等特殊情况，使用 ascii 字符集
  ENG_NAME_REGEX = /\A[\s\w_\-·]+\z/
  VALIDATION_FORMAT_SCOPE = ["activerecord", "attributes", "magic_bean/address", "errors", "format"].freeze

  REGION_NAME_HASH = {
    "Australian Capital Territory": "ACT",
    "New South Wales": "NSW",
    "Northern Territory": "NT",
    "Queensland": "QLD",
    "South Australia": "SA",
    "Tasmania": "TAS",
    "Victoria": "VIC",
    "Western Australia": "WA"
  }.stringify_keys

  # attr related macros
  enum housing_type: {
    house: 1, # 住宅
    apartment: 2, # 公寓
    office: 3, # 公司
  }

  # association macros
  belongs_to :user

  # validation macros
  validates_presence_of :tel_number, :postal_code, :province_name, :city_name
  validates_presence_of :street_number, :street, if: -> { detail_info.blank? || street_number_changed? || street_changed? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :first_name, presence: true, format: { with: ENG_NAME_REGEX, message: I18n.t("contains_only_english_or_dash_or_middot", scope: VALIDATION_FORMAT_SCOPE, locale: I18n.locale) }
  validates :last_name, presence: true, format: { with: ENG_NAME_REGEX, message: I18n.t("contains_only_english_or_dash_or_middot", scope: VALIDATION_FORMAT_SCOPE, locale: I18n.locale) }
  validates :detail_info, presence: true, format: { with: ENG_ADDRESS_REGEX, message: I18n.t("contains_only_ascii_chars", scope: VALIDATION_FORMAT_SCOPE, locale: I18n.locale) }
  validates :unit_number, format: { with: ENG_ADDRESS_REGEX, message: I18n.t("contains_only_ascii_chars", scope: VALIDATION_FORMAT_SCOPE, locale: I18n.locale) }, allow_blank: true
  validates :tel_number, format: { with: /\A\d{11}\z/ }
  validates_length_of :remark, maximum: 120, allow_blank: true
  validate :suburb_and_post_code_match
  validate :check_tel_number_format

  # callbacks
  before_validation :strip_fields, :format_tel_number, :set_detail_info
  before_save :set_self_default, if: :should_set_default?
  after_save :check_default_unique, if: :is_default?
  after_commit :set_other_default, on: :destroy, if: :is_default?

  # other macros

  # 这里的字段顺序不要改动，要跟数据库保持一致，不然会影响redis订单上限计数
  def to_order_json
    {
      id: id,
      type: "Address",
      email: email,
      street: street,
      city_name: city_name,
      last_name: last_name,
      first_name: first_name,
      tel_number: tel_number,
      detail_info: human_address,
      postal_code: postal_code,
      unit_number: unit_number,
      company_name: company_name,
      province_name: province_name,
      street_number: street_number,
      pure_detail_info: detail_info
    }.as_json
  end

  def human_address
    unit_number? ? "#{unit_number}/#{detail_info}" : detail_info
  end

  def receiver_name
    "#{ first_name } #{ last_name }"
  end

  private
  # 当前没有默认地址时，新建时设置为默认地址
  def should_set_default?
    !is_default && user.addresses.where(is_default: true).empty?
  end

  def set_self_default
    self.is_default = true
  end

  # 删除了默认地址后自动设置最新的为默认地址
  def set_other_default
    user.addresses.order(created_at: :desc)
      .first&.update(is_default: true)
  end

  # 更新为默认地址时，将其他默认地址置为 false
  def check_default_unique
    addresses = user.addresses
      .where.not(id: self.id)
      .where(is_default: true)

    addresses.update_all(is_default: false) if addresses.any?
  end

  def strip_fields
    [
      :tel_number, :email, :postal_code, :province_name, :city_name,
    ].each do |field|
      self[field] = self[field]&.strip
    end
  end

  def check_tel_number_format
    errors.add(:base, I18n.t("error.mobile.invalid_format")) unless Phony.plausible?(tel_number)
  end

  def set_detail_info
    self.detail_info = "#{street_number} #{street}" if street_number_changed? || street_changed?
  end

  def format_tel_number
    self.tel_number = tel_number&.gsub(" ", "")
  end

  def suburb_and_post_code_match
    self.errors.add(:base, I18n.t("error.address.invalid_suburb_or_postal_code")) unless MagicBean::AuSuburb.exists?(name: city_name, postal_code: postal_code)
  end
end
