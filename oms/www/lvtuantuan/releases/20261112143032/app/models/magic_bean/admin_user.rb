# frozen_string_literal: true
module MagicBean
  class AdminUser < ApplicationRecord
    include Redis::Objects

    # scope

    # constants
    EMAIL_PATTERN = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    PASSWORD_PATTERN = /(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[._!@#$%^&*])/
    ADMIN_MENUS = %w(
                  home data_analysis merchant_delivery_addresses_analysis
                  brands categories web_categories items qa_and_guarantees form_items form_item_applications
                  groupon_activities gift_activities sku_sales sku_returns sku_suppliers histories sku_in_stock_notices gift_orders_analyses pool_gift_orders_analyses gift_coupons_analyses
                  normal_orders groupon_orders virtual_orders warehouse_orders ae_orders logistics after_sales
                  order_analyses order_sales live_rooms mobile_blacklists
                  coupon_templates preferential_pools coupon_packages gift_card_templates promo_code_templates
                  role_templates admin_users operation_records admin_assign_integral_records users members user_suggestions user_recommended_products
                  site_configs payment_settings page_popups custom_lists banner_clicks custom_pages pages report_pages report_pages_preview hot_searches
                  app_download_channels multi_lang_configs auction/activities auction_orders
                  delivery_times self_pick_ups delivery_areas freight_templates freight_search
                  event_pages external_links external_mini_programs sku_sales_plan
                  push_messages marketing_messages time_limited_promotions extra_orders_limits coupon_auto_assignments sign_in_activities
                  overseas_student_applications item_banners same_day_delivery_times
                  web_banners web_custom_lists live_room_viewed_users live_room_orders
                  app_channel_orders web_channel_orders mini_program_channel_orders au_suburbs homepage_paging_settings third_party_orders mine_page_activity_settings
                  ae_items ae_drop_shipper_categories hot_sell_configs item_tag_types item_tag_groups item_tags top_left_item_tags sku_sales_mailer_settings
                  )
    SPECIAL_MENUS = %w(order_sales sku_sales home data_analysis merchant_delivery_addresses_analysis order_analyses sku_sales_plan sku_suppliers sku_returns gift_orders_analyses pool_gift_orders_analyses gift_coupons_analyses freight_search report_pages_preview ae_items ae_drop_shipper_categories ae_orders)
    MAX_LOGIN_ATTEMPTS = 5

    # attr related macros
    enum state: {
      active: 1,
      banned: 2
    }

    enum role: {
      super_admin: 1,
      store_admin: 2,
      store_assistant: 3
    }

    has_secure_password

    # association macros
    belongs_to :creator, class_name: "MagicBean::AdminUser", optional: true
    belongs_to :role_template, optional: true
    has_many :operation_records, dependent: :destroy
    has_many :admin_user_stores, dependent: :destroy
    has_many :stores, through: :admin_user_stores, source: :store

    # validation macros
    validates_presence_of :name, :state, :role, :mobile
    validates_uniqueness_of :mobile
    validates :email, format: { with: EMAIL_PATTERN }, if: -> { email.present? }
    validates_length_of :password, within: 8..72, allow_blank: true
    validates :password, format: { with: PASSWORD_PATTERN, message: "必须包含数字/大小写字母/特殊字符" }, if: :password_digest_changed?
    validates_length_of :stores, minimum: 1, unless: :super_admin?, too_short: "不能为空"

    # callbacks

    # other macros
    value :can_force_update_sku_price
    value :can_update_sku_new_user_price
    value :can_set_app_home_page

    # 目前只有启用/禁用，不引进状态机
    def toggle_state
      target_state = active? ? "banned" : "active"

      update(state: target_state)
    end

    def permissions_md5
      Digest::MD5.hexdigest(permissions.join(";"))
    end

    def categories
      MagicBean::Category.top.where(id: can_read_category_ids)
    end

    def can_read_category_ids=(value)
      write_attribute("can_read_category_ids", value.select(&:present?).uniq)
    end

    def can_not_force_update_sku_price?
      can_force_update_sku_price.value != "true"
    end

    def can_not_update_sku_new_user_price?
      can_update_sku_new_user_price.value != "true"
    end

    def can_set_app_home_page?
      can_set_app_home_page.value == "true"
    end    

    def access_locked?
      locked_at.present?
    end

    def attempts_exceeded?
      failed_attempts >= MAX_LOGIN_ATTEMPTS
    end

    def unlock_access!
      update_columns(failed_attempts: 0, locked_at: nil)
    end

    def reset_failed_attempts
      update_attribute(:failed_attempts, 0)
    end

    def increment_failed_attempts
      self.increment!(:failed_attempts)
      touch(:locked_at) if attempts_exceeded?

      reload
    end
  end
end
