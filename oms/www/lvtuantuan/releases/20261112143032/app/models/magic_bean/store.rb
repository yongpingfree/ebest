# frozen_string_literal: true

class MagicBean::Store < ApplicationRecord
  scope :default, -> { where(is_default: true) }
  scope :enabled, -> { where(disabled: false) }
  scope :sydney, -> { find_by(name: "Sydney") }

  has_many :admin_user_stores
  has_many :admin_users, through: :admin_user_stores, source: :admin_user
  has_many :share_settings, dependent: :restrict_with_error
  has_many :au_suburbs, dependent: :restrict_with_error
  has_many :items, dependent: :restrict_with_error
  has_many :stock_keeping_units, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :order_items, dependent: :restrict_with_error
  has_many :after_sales, dependent: :restrict_with_error
  has_many :coupon_packages, dependent: :restrict_with_error
  has_many :coupon_templates, dependent: :restrict_with_error
  has_many :coupons, dependent: :restrict_with_error
  has_many :freight_templates, dependent: :restrict_with_error
  has_many :gift_activities, dependent: :restrict_with_error
  has_many :groupon_activities, dependent: :restrict_with_error
  has_many :groupons, dependent: :restrict_with_error
  has_many :self_pick_ups, dependent: :restrict_with_error
  has_many :shopping_cart_items, dependent: :restrict_with_error
  has_many :custom_lists, dependent: :destroy
  has_many :custom_list_items, dependent: :destroy
  has_many :custom_pages, dependent: :destroy
  has_many :page_popups, dependent: :destroy
  has_many :operation_records, dependent: :destroy
  has_one :site_config
  has_one :payment_setting, dependent: :destroy
  belongs_to :default_au_suburb, class_name: "MagicBean::AuSuburb", optional: true

  before_create :initialize_site_config, :init_home_custom_page, :initialize_payment_setting
  after_save :set_default_store, if: :is_default

  # validates :short_name, presence: true, uniqueness: true, format: { with: /A[A-Z]+z/, allow_blank: true }
  validates :short_name, presence: true, uniqueness: true, format: { with: /\A[A-Z]+\z/, allow_blank: true }
  validate :check_short_name, on: :update, if: :short_name_changed?

  def current_time_zone
    site_config&.custom_time_zone.presence || TIME_ZONE
  end

  def app_path
    { type: "store", params: { id: id, name: name, default_au_suburb_name: default_au_suburb&.name,   default_au_suburb_postal_code: default_au_suburb&.postal_code } }.to_json
  end

  def peti_store?
    name == "peti"
  end

  private
  def set_default_store
    MagicBean::Store.default.where.not(id: self.id).update_all(is_default: false)
  end

  def initialize_site_config
    default_site_config = MagicBean::SiteConfig.default_config
    self.site_config = MagicBean::SiteConfig.new(
      {
        return_receiver_properties: default_site_config&.return_receiver_properties,
        cutoff_time: default_site_config&.cutoff_time.presence || [{ time: "22:45", earliest_delivery_time: "08:00-12:00", time_kind: "next_day" }]
      }
    )
  end

  def initialize_payment_setting
    self.payment_setting = MagicBean::PaymentSetting.new(
      wechat_service_percentage: 0,
      vm_credit_card_service_percentage: 0,
      unionpay_credit_card_service_percentage: 0,
      exchange_rate_rise_percentage: 0,
      omipay_wechat_service_percentage: 0,
      omipay_alipay_service_percentage: 0,
      supay_wechat_service_percentage: -1,
      supay_alipay_service_percentage: -1,
      enable_commweb_3ds_auth: true,
      apple_pay_service_percentage: 0,
      cba_apple_pay_service_percentage: 0,
      cba_google_pay_service_percentage: 0
    )
  end

  def init_home_custom_page
    self.custom_pages.build(
      [
        { name: "首页", en_name: "home" },
        { name: "首页 v2", en_name: "home_v2" }
      ]
    ) if custom_pages.blank?
  end

  def check_short_name
    errors.add(:short_name, "已有关联发票，不能修改") if MagicBean::OrderInvoice.joins(:order).exists?(orders: { store_id: id })
  end
end
