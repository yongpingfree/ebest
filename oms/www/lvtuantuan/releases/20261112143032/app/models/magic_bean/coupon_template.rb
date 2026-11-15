# frozen_string_literal: true
require "open-uri"

module MagicBean
  class CouponTemplate < ApplicationRecord
    include PriceConvertConcern
    include GenerateCodeConcern
    include Redis::Objects
    include FileUploadConcern
    include QrcodeConcern
    include Order::Messages

    # scope
    scope :active, -> { where("enabled = true AND (time_kind != 1 OR (time_kind = 1 AND end_at >= :time))", { time: Time.current }) }
    scope :enabled, -> { where(enabled: true) }
    scope :item_display, -> { where(display_in_item_detail: true) }

    # constants
    FRESSH_COUPON_RANGE = [
      [0, 100],
      [101, 200],
      [201, 400],
      [401, 600],
      [601, 800],
      [801, 1000],
      [1001, 1200],
      [1201, 1400],
      [1401, 1600],
      [1601, 1800],
      [1801, 2200],
      [2201, 2500],
      [2501, 3000]
    ]
    MAX_COUNPON_SIZE_PER_JOB = 200
    LARGE_QUANTITY_COUPON_JOB_INTERNAL = 10

    # attr related macros
    alias_attribute :name, :title
    alias_attribute :expired_at, :end_at
    convert_price_to_yuan :denominations_in_cent, :at_least_amount_in_cent, :min_denominations_in_cent, :max_denominations_in_cent

    set :coupon_codes
    set :collected_user_ids

    enum target_kind: {
      item: 1,
      freight: 2
    }

    enum kind: {
      discount: 1,
      reduction: 2,
      random_reduction: 3
    }

    # 使用类型
    enum usage_kind: {
      marketing: 1,
      after_sale: 2
    }

    enum time_kind: {
      fixed_period: 1,
      first_day: 2,     # 领取首日后 time_limit_in_day 内可用
      next_day: 3       # 领取次日后 time_limit_in_day 内可用
    }

    enum user_kind: {
      all_user: 1, # 所有用户
      member: 2,   # 会员
      new_user: 3  # 新用户
    }

    enum channel: {
      general: 1,
      mini_program: 2,
      app: 3,
      web: 4
    }

    enum party: {
      ebest_inside: 1,
      ebest_outside: 2
    }

    enum cost_accounting: {
      platform: 1, # 平台
      segment: 2 # 为板块
    }

    translates :title
    globalize_accessors attributes: [:title]

    # association macros
    has_many :coupons, dependent: :destroy
    has_many :users, through: :coupons
    belongs_to :store, optional: true
    has_many :operation_records, dependent: :destroy, as: :operatable
    has_many :random_reduction_coupon_template_rules, inverse_of: :coupon_template, dependent: :destroy

    accepts_nested_attributes_for :random_reduction_coupon_template_rules, allow_destroy: true

    # validation macros
    before_validation :set_at_least_amount_in_cent
    validates_presence_of :title, :details_image
    validate :check_start_at_and_end_at_valid, :check_assign_start_at_and_end_at_valid, :at_most_one_of_ids_array, :check_payment_types

    # 如果是满减，减的面额需要必填且大于0
    with_options if: :reduction? do |memo|
      memo.validates :denominations_in_cent,
        presence: true,
        numericality: {
          greater_than: 0
        }
    end

    # 随机满减，面额都需要必填且大于0
    with_options if: :random_reduction? do
      validates :max_random_reduction_count, presence: true, numericality: { greater_than: 0 }
      validate :max_random_reduction_count_eq_to_sum_quantity_of_rules
    end


    # 如果是打折，折扣值需要必填且大于0
    with_options if: :discount? do |memo|
      memo.validates :discount,
        presence: true,
        numericality: {
          greater_than: 0,
          less_than: 10
        }
    end

    # 如果有门槛，订单满减金额必填且大于0
    with_options if: :need_at_least_amount? do |memo|
      memo.validates :at_least_amount_in_cent,
        presence: true,
        numericality: {
          greater_than_or_equal_to: 0
        }
    end

    # 如果固定日期，开始时间与结束时间必填
    with_options if: :fixed_period? do |memo|
      memo.validates :start_at, presence: true
      memo.validates :end_at, presence: true
    end

    # 如果不固定时间，则需要填有效天数
    with_options unless: :fixed_period? do |memo|
      memo.validates :time_limit_in_day, presence: true
    end

    # callbacks
    before_create :generate_code, if: -> { code.nil? }
    before_create :set_title_i18n
    after_commit :enqueue_generate_qrcode_job, on: :create
    after_commit :enqueue_expired_fixed_period_coupons_Job, if: :saved_change_to_end_at?

    # other macros
    attr_accessor :updated_by_admin

    ransacker :kind, formatter: proc { |v| kinds[v] }
    ransacker :usage_kind, formatter: proc { |v| usage_kinds[v] }

    delegate :title, to: :item, prefix: true, allow_nil: true

    def assign_coupon(user, coupon_code = nil)
      transaction do
        user_id = user.id

        if member? && user.member.nil?
          errors.add(:base, I18n.t("error.coupon_template.not_a_member"))
          return false
        end

        if new_user? && !user.new_user
          errors.add(:base, I18n.t("error.coupon_template.not_new_user"))
          return false
        end

        if unassignable?
          errors.add(:base, I18n.t("error.coupon_template.timeout"))
          return false
        end

        unless (!fixed_period? || (fixed_period? && end_at >= Time.current))
          errors.add(:base, I18n.t("error.coupon_template.expired"))
          return false
        end

        if coupons.where(user_id: user_id).where("assigned_at between ? and ?", Date.current.beginning_of_day, Date.current.end_of_day).exists?
          errors.add(:base, I18n.t("error.coupon_template.already_claimed_today"))
          return false
        end

        if assign_quantity_limit?(user_id)
          errors.add(:base, I18n.t("error.coupon_template.reach_max_count", quantity: assign_total_quantity))
          return false
        end

        # 检查当前用户是否在领取列表中，如果还在列表中说明正在抢券
        unless collected_user_ids.add(user_id)
          errors.add(:base, I18n.t("error.coupon_template.getting_coupons"))
          return false
        end

        # 如果是指定优惠券码, 则需要检查该码是否还存在，不存在则意味已领取
        if coupon_code
          if coupon_codes.member?(coupon_code)
            coupon_codes.delete(coupon_code)
          else
            coupon_code = nil
          end
        else
          coupon_code = coupon_codes.pop
        end

        if coupon_code.nil?
          # 如果优惠券被抢完，从collected_user_ids移除当前用户，避免后续增加生成优惠券数量时当前用户无法领取
          collected_user_ids.delete(user_id)
          errors.add(:base, I18n.t("error.coupon_template.no_more_coupons"))

          return false
        end

        coupon = MagicBean::Coupon.find_by!(code: coupon_code)
        coupon.update_assign_info(user)
        # 用户不再限制只能领取一次，领取成功后collected_user_ids移除当前用户
        collected_user_ids.delete(user_id)

        [true, coupon]
      end
    rescue => e
      collected_user_ids.delete(user.id)
      coupon_codes << coupon_code
      raise e
    end

    def active?
      enabled && (!fixed_period? || (fixed_period? && end_at >= Time.current))
    end

    def unassignable?
      assign_start_at && assign_end_at && !Time.current.between?(assign_start_at, assign_end_at)
    end

    def assign_quantity_limit?(user_id)
      if assign_total_quantity.to_i.positive?
        if assign_start_at.present? && assign_end_at.present?
          coupons.where(user_id: user_id).where("assigned_at between ? and ?", assign_start_at, assign_end_at).count >= assign_total_quantity
        else
          coupons.where(user_id: user_id).count >= assign_total_quantity
        end
      else
        false
      end
    end

    def generate_large_quantity_coupons(total, admin_user_id = nil)
      count = total / MAX_COUNPON_SIZE_PER_JOB
      remainder = total % MAX_COUNPON_SIZE_PER_JOB

      # 余数部分的优惠券生成马上执行
      if remainder.positive?
        GenerateCouponsJob.perform_later(id, remainder, admin_user_id)
      end

      count.times do |n|
        # 每 10 分钟加一个随机分钟数，把生成优惠券 job 分散执行
        wait_time = (LARGE_QUANTITY_COUPON_JOB_INTERNAL * n + rand(LARGE_QUANTITY_COUPON_JOB_INTERNAL)).minutes
        GenerateCouponsJob.set(wait: wait_time).perform_later(id, MAX_COUNPON_SIZE_PER_JOB, admin_user_id)
      end
    end

    def generate_coupons(qty = 1, options = {})
      new_coupons = []
      transaction do
        coupon_attributes = {
          kind: discount? ? kind : "reduction",
          title: title_zh_cn,
          desc: desc,
          target_kind: target_kind,
          time_kind: time_kind,
          channel: channel,
          item_ids: item_ids,
          custom_list_ids: custom_list_ids,
          store_id: store_id,
          category_ids: category_ids,
          sub_category_ids: sub_category_ids,
          brand_ids: brand_ids,
          delivery_types: delivery_types,
          payment_types: payment_types,
          party: party
        }

        # 如果是固定时间的话则可以设置过期时间，否则需要领取后才能设置
        if fixed_period?
          coupon_attributes[:expired_at] = end_at
          coupon_attributes[:start_at] = start_at
        else
          coupon_attributes[:start_at] = Time.current
        end

        coupon_attributes_arrays = Array.new(qty.to_i) do
          new_options = options.merge(
            preferences: {
              denominations_in_cent: random_reduction? ? fetch_a_random_reduction_amount : denominations_in_cent,
              at_least_amount_in_cent: at_least_amount_in_cent,
              need_at_least_amount: need_at_least_amount,
              discount: discount,
              time_limit_in_day: time_limit_in_day
            }
          )
          coupon_attributes.merge(new_options)
        end

        new_coupons = coupons.create(coupon_attributes_arrays)

        redis.multi do
          push_coupon_codes_to_redis(new_coupons)
        end
      end
      new_coupons
    end

    # 这个方法会发推送给用户说发放了优惠券
    def generate_coupon_and_assign_with_notification(user_id, coupon_type = "normal", invitee_id = nil)
      return unless user_id

      transaction do
        time_current = Time.current

        coupon_attributes = {
          # 优惠券只有折扣跟满减两种类型
          kind: discount? ? kind : "reduction",
          title: title_zh_cn,
          desc: desc,
          target_kind: target_kind,
          time_kind: time_kind,
          channel: channel,
          item_ids: item_ids,
          custom_list_ids: custom_list_ids,
          store_id: store_id,
          category_ids: category_ids,
          sub_category_ids: sub_category_ids,
          brand_ids: brand_ids,
          delivery_types: delivery_types,
          payment_types: payment_types,
          party: party,
          assigned_at: time_current,
          user_id: user_id,
          coupon_type: coupon_type,
          invitee_id: invitee_id,
          preferences: {
            denominations_in_cent: random_reduction? ? fetch_a_random_reduction_amount : denominations_in_cent,
            at_least_amount_in_cent: at_least_amount_in_cent,
            need_at_least_amount: need_at_least_amount,
            discount: discount,
            time_limit_in_day: time_limit_in_day
          }
        }

        # 如果是固定时间的话则可以设置过期时间，否则需要领取后才能设置
        if fixed_period?
          coupon_attributes[:expired_at] = end_at
          coupon_attributes[:start_at] = start_at
        else
          coupon_attributes[:start_at] = time_current
          coupon_attributes[:start_at] += 1.day if next_day?
          coupon_attributes[:expired_at] = coupon_attributes[:start_at] + time_limit_in_day.days if time_limit_in_day > 0
        end

        new_coupon = coupons.create(coupon_attributes)
        increase_users_count!

        new_coupon.create_assign_coupon_app_text_message
        new_coupon
      end
    end

    # 这个方法不会发推送
    def generate_coupons_and_assign_to_users(user_ids)
      qty = user_ids.size
      return unless qty.positive?

      transaction do
        time_current = Time.current

        coupon_attributes = {
          # 优惠券只有折扣跟满减两种类型
          kind: discount? ? kind : "reduction",
          title: title_zh_cn,
          desc: desc,
          target_kind: target_kind,
          time_kind: time_kind,
          channel: channel,
          item_ids: item_ids,
          custom_list_ids: custom_list_ids,
          store_id: store_id,
          category_ids: category_ids,
          sub_category_ids: sub_category_ids,
          brand_ids: brand_ids,
          delivery_types: delivery_types,
          payment_types: payment_types,
          party: party,
          assigned_at: time_current
        }

        # 如果是固定时间的话则可以设置过期时间，否则需要领取后才能设置
        if fixed_period?
          coupon_attributes[:expired_at] = end_at
          coupon_attributes[:start_at] = start_at
        else
          coupon_attributes[:start_at] = time_current
          coupon_attributes[:start_at] += 1.day if next_day?
          coupon_attributes[:expired_at] = coupon_attributes[:start_at] + time_limit_in_day.days if time_limit_in_day > 0
        end

        coupon_attributes_arrays = Array.new(qty.to_i) do |index|
          new_options = {
            user_id: user_ids[index],
            preferences: {
              denominations_in_cent: random_reduction? ? fetch_a_random_reduction_amount : denominations_in_cent,
              at_least_amount_in_cent: at_least_amount_in_cent,
              need_at_least_amount: need_at_least_amount,
              discount: discount,
              time_limit_in_day: time_limit_in_day
            }
          }
          coupon_attributes.merge(new_options)
        end
        new_coupons = coupons.create(coupon_attributes_arrays)
        increase_users_count!(qty)

        new_coupons
      end
    end

    # 将优惠券码存在 redis 中
    def push_coupon_codes_to_redis(new_coupons)
      coupon_codes << new_coupons.pluck(:code)
    end

    # 可用优惠券数
    def avaliable_coupons_count
      coupon_codes.size
    end

    def mini_program_path
      "pages/coupon/coupon-template-detail/coupon-template-detail?code=#{code}"
    end

    def app_path
      { type: "couponTemplateDetail", params: { code: code } }.to_json
    end

    def increase_users_count!(qty = 1)
      increment!(:users_count, qty)
    end

    def increase_orders_count!
      increment!(:orders_count)
    end

    def decrease_orders_count!
      decrement!(:orders_count)
    end

    def items
      item_ids.present? ? MagicBean::Item.includes(:translations).where(id: item_ids) : []
    end

    def item_ids=(value)
      write_attribute("item_ids", value.select(&:present?).uniq)
    end

    def custom_lists
      custom_list_ids.present? ? MagicBean::CustomList.includes(:translations).where(id: custom_list_ids) : []
    end

    def custom_list_items
      if custom_list_ids.present?
        MagicBean::Item.includes(:translations).where(id:  MagicBean::CustomListItem.where(custom_list_id: custom_list_ids).select(:item_id))
      else
        []
      end
    end

    def custom_list_ids=(value)
      write_attribute("custom_list_ids", value.select(&:present?).uniq)
    end

    def categories
      category_ids.present? ? MagicBean::Category.includes(:translations).top.where(id: category_ids) : []
    end

    def category_ids=(value)
      write_attribute("category_ids", value.select(&:present?).uniq)
    end

    def sub_categories
      sub_category_ids.present? ? MagicBean::Category.includes(:translations).children.where(id: sub_category_ids) : []
    end

    def sub_category_ids=(value)
      write_attribute("sub_category_ids", value.select(&:present?).uniq)
    end

    def brands
      brand_ids.present? ? MagicBean::Brand.includes(:translations).where(id: brand_ids) : []
    end

    def brand_ids=(value)
      write_attribute("brand_ids", value.select(&:present?).uniq)
    end

    def can_edit?
      coupons.blank?
    end

    def instruction
      # TODO: 确认这部分英文翻译
      if category_ids.present?
        self.class.human_attribute_name("category_instruction", content: categories.first(4).pluck(:name).join("，").truncate(15))
      elsif item_ids.present? || custom_list_ids.present?
        self.class.human_attribute_name("item_instruction", content: (items + custom_list_items).first(3).pluck(:title).join("，").truncate(15))
      elsif sub_category_ids.present?
        self.class.human_attribute_name("category_instruction", content: sub_categories.first(4).pluck(:name).join("，").truncate(15))
      elsif brand_ids.present?
        self.class.human_attribute_name("brand_instruction", content: brands.first(4).pluck(:name).join("，").truncate(15))
      else
        at_least_amount_in_cent.present? ? self.class.human_attribute_name("at_least_amount_instruction", content: at_least_amount_in_yuan) : self.class.human_attribute_name("general_instruction")
      end
    end

    def title_with_store
      title_zh_cn + (store_id? ? "（#{store&.name}）" : "（全店通用）")
    end

    # class methods
    class << self
      def newbie(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        where(id: store_config&.newbie_coupon_template_ids)
      end

      def web_newbie(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        where(id: store_config&.web_newbie_coupon_template_ids)
      end

      def invited(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        where(id: store_config&.invited_coupon_template_ids)
      end

      def web_invited(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        where(id: store_config&.web_invited_coupon_template_ids)
      end

      def newbie_and_invited(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config

        newbie_coupon_template_ids = store_config&.newbie_coupon_template_ids
        invited_coupon_template_ids = store_config&.invited_coupon_template_ids
        where(id: (newbie_coupon_template_ids || []) + (invited_coupon_template_ids || []))
      end

      def finish_order_to_inviter(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        where(id: store_config&.finish_order_coupon_template_ids_to_inviter)
      end

      def web_finish_order_to_inviter(store_id = nil)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        where(id: store_config&.web_finish_order_coupon_template_ids_to_inviter)
      end

      def birthday(store_id)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        find_by(id: store_config&.birthday_coupon_template_id)
      end

      def web_birthday(store_id)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        find_by(id: store_config&.web_birthday_coupon_template_id)
      end

      def info_finished(store_id)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        find_by(id: store_config&.info_finished_coupon_template_id)
      end

      def web_info_finished(store_id)
        store_config = MagicBean::SiteConfig.find_by(store_id: store_id) if store_id.present?
        store_config ||= MagicBean::SiteConfig.default_config
        find_by(id: store_config&.web_info_finished_coupon_template_id)
      end

      def assign_coupon_from_fresh_balance(user, balance_in_cent)
        ct = nil
        FRESSH_COUPON_RANGE.each do |range|
          if balance_in_cent.between?(range[0], range[1])
            ct = self.find_by(code: "fresh#{range[1]/100}")
            break
          end
        end

        ct.generate_coupons.first.assign_to_user(user) if ct
      end

      def batch_assign_coupons_via_csv_file(coupon_template_id, file_url, admin_user_id)
        coupon_template = MagicBean::CouponTemplate.find_by(id: coupon_template_id)
        return if coupon_template.nil?

        admin_user = MagicBean::AdminUser.find_by(id: admin_user_id)
        return if admin_user.nil?

        # file_url 只应来自管理端 aws_upload!，白名单外地址（含 file://、内网地址）一律拒绝，防 SSRF
        raise ArgumentError, "文件地址不受支持，请通过后台上传后导入" unless Validators::ResourceUrl.valid_file_url?(file_url)

        input_mobiles = []
        CSV.new(URI.open(file_url), headers: true).each do |row|
          mobile = row["mobile"]&.strip
          input_mobiles << mobile if mobile.present?
        end

        new_coupons = coupon_template.generate_coupons(input_mobiles.size)

        success_mobiles = []
        failed_mobiles = []
        new_coupons.each do |coupon|
          mobile = input_mobiles.shift
          member = MagicBean::Member.includes(:user).find_by(mobile: mobile)
          if member.nil?
            failed_mobiles << mobile
            next
          end

          coupon.update_assign_info(member.user)

          if coupon.valid?
            success_mobiles << mobile
          else
            failed_mobiles << mobile
          end
        end

        BatchAssignCouponMailer.export(coupon_template, success_mobiles, failed_mobiles, admin_user.email).deliver_later

        admin_user.operation_records.create(operatable: coupon_template, content: "通过文件 #{file_url} 批量分配优惠券", store_id: coupon_template.store_id)

        [success_mobiles, failed_mobiles]
      end
    end

    def fetch_a_random_reduction_rule
      random_reduction_coupon_template_rules.avaliable.sample
    end

    def fetch_a_random_reduction_amount
      rule = fetch_a_random_reduction_rule

      raise ActiveRecord::Rollback, I18n.t("error.coupon_template.no_more_coupons") if rule.nil?

      rule.increment_used_quantity!
      amount = rand(rule.min_amount_in_cent..rule.max_amount_in_cent)
    end

    def reach_max_random_reduction_count?(new_quantity)
      random_reduction? && (coupons_count + new_quantity > max_random_reduction_count)
    end

    private

    # 生成二维码需要的参数
    def qrcode_params
      {
        sence: "code=#{code}",
        path: "pages/coupon/coupon-template-detail/coupon-template-detail"
      }
    end

    def check_assign_start_at_and_end_at_valid
      if [assign_start_at, assign_end_at].select(&:present?).count == 1
        errors.add(:base, "领取开始时间和结束时间必须都填写或都不填")
      elsif assign_start_at && assign_end_at && assign_start_at > assign_end_at
        errors.add(:base, "领取开始时间不能大于领取结束时间")
      end
    end

    def check_start_at_and_end_at_valid
      errors.add(:base, I18n.t("errors.messages.start_at_can_not_later_than_end_at")) if start_at && end_at && start_at > end_at
    end

    def at_most_one_of_ids_array
      count = 0
      count += 1 if item_ids.present?
      count += 1 if category_ids.present?
      count += 1 if sub_category_ids.present?
      count += 1 if brand_ids.present?

      errors.add(:base, "一二级分类、产品、品牌最多只能关联一种类型") if count > 1
    end

    def enqueue_expired_fixed_period_coupons_Job
      return unless fixed_period?
      ExpiredFixedPeriodCouponsJob.set(wait_until: end_at).perform_later(id)
    end

    def check_payment_types
      errors.add(:base, "仅App优惠券可设置支付类型") if !app? && payment_types.present?
    end

    def set_title_i18n
      self.title_zh_tw = Ropencc.conv("s2tw.json", title_zh_cn) if title_zh_tw.blank?
      self.title_en = EasyTranslate.translate(title_zh_cn, from: :"zh-CN", to: :en) if title_en.blank?
    end

    def max_random_reduction_count_eq_to_sum_quantity_of_rules
      return unless updated_by_admin

      total_quantity_of_rules = random_reduction_coupon_template_rules.to_a.select { |rule| rule._destroy != true }.sum(&:max_quantity)

      if total_quantity_of_rules != max_random_reduction_count
        self.errors.add(:max_random_reduction_count, "须等于比例张数之和")
      end
    end

    def set_at_least_amount_in_cent
      self.at_least_amount_in_cent = nil unless need_at_least_amount
    end
  end
end
