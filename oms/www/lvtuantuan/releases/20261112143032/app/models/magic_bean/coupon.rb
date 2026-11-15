# frozen_string_literal: true
module MagicBean
  class Coupon < ApplicationRecord
    # 优惠券
    include GenerateCodeConcern
    include PriceConvertConcern
    # 目前include该模块是为了直接使用assign_to_user方法里使用redis方法
    include Redis::Objects
    include QrcodeConcern
    include FileUploadConcern
    include Order::Messages

    # scope
    scope :usable, -> { pending.where("start_at <= :time AND (expired_at IS NULL OR expired_at >= :time)", time: Time.current) }
    scope :active, -> { pending.where("expired_at IS NULL OR expired_at >= :time", time: Time.current) }
    scope :inactive, -> { where("expired_at < :time OR status IN (2,3)", time: Time.current) }
    scope :assignable, -> { active.where(user_id: nil) }

    # constants

    # attr related macros
    convert_price_to_yuan :denominations_in_cent, :at_least_amount_in_cent

    enum target_kind: {
      item: 1,
      freight: 2
    }

    enum status: {
      pending: 1,
      used: 2,
      expired: 3
    }

    enum kind: {
      discount: 1,
      reduction: 2
    }

    enum time_kind: {
      fixed_period: 1,
      first_day: 2,     # 领取首日后 time_limit_in_day 内可用
      next_day: 3       # 领取次日后 time_limit_in_day 内可用
    }

    enum channel: {
      general: 1,
      mini_program: 2,
      app: 3,
      web: 4
    }

    enum coupon_type: {
      normal: 1,
      invite: 2
    }

    enum party: {
      ebest_inside: 1,
      ebest_outside: 2
    }

    delegate :details_image, :expired_image, :ticket_image, to: :coupon_template, allow_nil: true
    delegate :title, to: :coupon_template, allow_nil: true, prefix: true
    delegate :no, :id, :type, to: :order, allow_nil: true, prefix: true

    # association macros
    belongs_to :coupon_template, counter_cache: true
    belongs_to :user, optional: true
    belongs_to :store, optional: true
    belongs_to :invitee, class_name: "MagicBean::Member", optional: true
    has_one :order, -> { trade_not_close }, class_name: "MagicBean::Order"
    has_many :operation_records, dependent: :destroy, as: :operatable

    # validation macros

    # callbacks
    before_validation :reset_item_ids
    before_create :generate_code
    after_commit :enqueue_expired_promotion_job, :delete_from_redis, if: :saved_change_to_user_id?
    after_destroy :delete_from_redis
    after_update :increase_coupon_template_orders_count!, if: :saved_change_to_used?
    after_update :decrease_coupon_template_orders_count!, if: :saved_change_to_pending?

    # other macros
    ransacker :status, formatter: proc { |v| statuses[v] }

    %w(denominations_in_cent discount at_least_amount_in_cent need_at_least_amount time_limit_in_day).each do |attr_name|
      define_method attr_name do
        @attr_name = preferences[attr_name]
      end
    end

    def usable?(current_order = nil, current_channel = nil)
      # 有效期内
      within_validity =
        if expired_at.nil?
          Time.current >= start_at
        else
          pending? && Time.current.between?(start_at, expired_at)
        end

      return false unless within_validity
      return false if current_channel && !self.channel.in?([current_channel, "general"])
      return false if coupon_template.new_user? && !user&.new_user

      if current_order
        # 如果是运费券且订单运费为0，则返回false
        return false if freight? && current_order.original_freight_in_cent.zero? && current_order.time_period_fee_in_cent.zero? && current_order.long_distance_fee_in_cent.zero?
        # 未达到满减要求，则返回false
        return false if need_at_least_amount && original_payment_amount_discounted_part(current_order) < at_least_amount_in_cent
        # 优惠券如果设置了配送类型，判断当前订单配送方式是否符合
        return false if invalid_for_delivery?(current_order.delivery_type)

        items = current_order.order_items.map(&:item).select { |item| item.coupon_enabled? }
        return false if items.empty?

        if category_ids.present?
          order_category_ids = items.map(&:category).map(&:parent).pluck(:id)
          order_minor_parent_category_ids = items.map(&:minor_category).compact.map(&:parent).pluck(:id)

          (order_category_ids & category_ids).present? || (order_minor_parent_category_ids & category_ids).present?
        elsif item_ids.present? || custom_list_ids.present?
          (items.pluck(:id) & all_item_ids).present?
        elsif sub_category_ids.present?
          order_category_ids = items.map(&:category).pluck(:id)
          order_minor_category_ids = items.map(&:minor_category).compact.pluck(:id)

          (order_category_ids & sub_category_ids).present? || (order_minor_category_ids & sub_category_ids).present?
        elsif brand_ids.present?
          order_brand_ids = items.pluck(:brand_id)

          (order_brand_ids & brand_ids).present?
        else
          true
        end
      else
        true
      end
    end

    def invalid_for_delivery?(order_delivery_type)
      delivery_types.present? && delivery_types.exclude?(order_delivery_type)
    end

    def delete_from_redis
      coupon_template.coupon_codes.delete(code)
    end

    def received?
      user_id?
    end

    # Coupon 直接调用
    # 分配优惠券
    def assign_to_user(user, coupon_type = "normal", invitee_id = nil, send_notification = false)
      transaction do
        redis.multi do
          if user_id
            errors.add(:base, I18n.t("error.coupon.already_assigned"))

            return false
          end

          coupon_template.collected_user_ids.add(user.id)
          delete_from_redis

          update_assign_info(user, coupon_type, invitee_id)
        end
      end
      create_assign_coupon_app_text_message if send_notification
    rescue => e
      coupon_template.collected_user_ids.delete(user.id)
      coupon_template.coupon_codes << code
      raise e
    end

    def update_assign_info(user, coupon_type = "normal", invitee_id = nil)
      self.user_id = user.id
      self.invitee_id = invitee_id
      self.coupon_type = coupon_type

      time_current = Time.current
      # 如果不是固定时间，则需要计算有效时间
      unless fixed_period?
        self.start_at = time_current
        self.start_at += 1.day if next_day?
        self.expired_at = self.start_at + time_limit_in_day.days if time_limit_in_day > 0
      end

      self.assigned_at = time_current

      save
      coupon_template.increase_users_count!
    end

    def real_discount
      discount / 10
    end

    # 计算订单优惠后价格
    # 商品优惠券不抵扣运费
    def calculate_discount_payment(order)
      amount_in_cent = order.total_payment_in_cent
      if usable?(order, order.channel)
        if discount?
          amount_in_cent - discount_amount(order)
        else
          total_payment_in_cent = amount_in_cent - [original_payment_amount_discounted_part(order), denominations_in_cent].min
          total_payment_in_cent < 0 ? 0 : total_payment_in_cent
        end
      else
        order.coupon = nil
        amount_in_cent
      end
    end

    def calculate_freight(order)
      freight_in_cent = order.freight_in_cent
      unless usable?(order, order.channel)
        order.coupon = nil
        return freight_in_cent
      end

      if discount?
        freight_in_cent * real_discount
      else
        freight_in_cent = freight_in_cent - denominations_in_cent
        freight_in_cent < 0 ? 0 : freight_in_cent
      end
    end

    # 计算订单项实际单价
    def calculate_order_item_base_price_in_cent(order_item)
      price_in_cent = order_item.pool_price_in_cent || order_item.price_in_cent

      return price_in_cent if (item_ids.present? || custom_list_ids.present?) && all_item_ids.exclude?(order_item.item_id)
      return price_in_cent if category_ids.present? && category_ids.exclude?(order_item.item.category.parent_id)
      return price_in_cent if sub_category_ids.present? && (sub_category_ids.exclude?(order_item.item.category_id) && sub_category_ids.exclude?(order_item.item.minor_category_id))
      return price_in_cent if brand_ids.present? && brand_ids.exclude?(order_item.item.brand_id)

      if discount?
        price_in_cent * real_discount
      else
        discounted_part = original_payment_amount_discounted_part(order_item.order)
        return price_in_cent if discounted_part.zero?
        # 优惠券的满减额度可能大于订单总金额，所以这里取二者较小值
        price_in_cent - (price_in_cent.to_f / discounted_part * [denominations_in_cent, discounted_part].min).floor
      end
    end

    def instruction
      coupon_template.instruction
    end

    # 生成二维码需要的参数
    def qrcode_params
      {
        sence: "code=#{coupon_template.code}&c_code=#{code}",
        path: "pages/coupon/coupon-template-detail/coupon-template-detail"
      }
    end

    def destroyable?
      pending? || expired?
    end

    def custom_list_items
      if custom_list_ids.present?
        MagicBean::Item.where(id:  MagicBean::CustomListItem.where(custom_list_id: custom_list_ids).select(:item_id))
      else
        []
      end
    end

    def all_item_ids
      item_ids + custom_list_items.pluck(:id)
    end

    private

    # 订单中参与优惠的订单项总金额
    def original_payment_amount_discounted_part(order)
      coupon_enabled_order_items = order.order_items.select { |oi| oi.item.coupon_enabled? }

      if category_ids.present?
        coupon_enabled_order_items.select { |order_item| category_ids.include?(order_item.item.parent_category_id) || category_ids.include?(order_item.item.minor_category&.parent_id) }
      elsif item_ids.present? || custom_list_ids.present?
        coupon_enabled_order_items.select { |order_item| all_item_ids.include?(order_item.item_id) }
      elsif sub_category_ids.present?
        coupon_enabled_order_items.select { |order_item| sub_category_ids.include?(order_item.item.category_id) || sub_category_ids.include?(order_item.item.minor_category_id) }
      elsif brand_ids.present?
        coupon_enabled_order_items.select { |order_item| brand_ids.include?(order_item.item.brand_id) }
      else
        coupon_enabled_order_items
      end.map { |item| item.pool_price_in_cent.present? ? item.pool_amount_in_cent : item.amount_in_cent }.sum
    end

    # 订单优惠金额
    def discount_amount(order)
      original_payment_amount_discounted_part(order) * (1 - real_discount)
    end

    def enqueue_expired_promotion_job
      ExpiredCouponJob.set(wait_until: expired_at).perform_later(id) if !fixed_period? && expired_at
    end

    def increase_coupon_template_orders_count!
      coupon_template.increase_orders_count!
    end

    def decrease_coupon_template_orders_count!
      coupon_template.decrease_orders_count!
    end

    def saved_change_to_used?
      saved_change_to_status? && used?
    end

    def saved_change_to_pending?
      saved_change_to_status? && pending?
    end

    def reset_item_ids
      self.item_ids = [] if category_ids.present?
    end
  end
end
