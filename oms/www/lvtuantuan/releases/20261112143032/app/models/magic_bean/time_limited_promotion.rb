# frozen_string_literal: true

module MagicBean
  class TimeLimitedPromotion < ApplicationRecord
    include AASM
    include PriceConvertConcern
    include LoadRemoteXlsxConcern

    # constants
    TAGS = %w[限时优惠 限時優惠]

    # concerns

    # attr related macros
    convert_price_to_yuan :price_in_cent

    enum state: { pending: 0, activated: 1, finished: 2 }, _suffix: true

    # association macros
    belongs_to :store
    has_many :time_limited_promotion_prices, dependent: :destroy
    has_many :sort_time_limited_promotion_prices, -> { sort_by_position }, class_name: "MagicBean::TimeLimitedPromotionPrice"
    accepts_nested_attributes_for :time_limited_promotion_prices, allow_destroy: true
    has_many :stock_keeping_units, through: :time_limited_promotion_prices

    # validation macros
    validates :title, presence: true
    validates :start_at, presence: true, timeliness: { before: :end_at }
    validates :end_at, presence: true, timeliness: { after: lambda { Time.current }, message: "需大于当前时间" }, if: :pending_state?
    validate :all_promotion_price_greater_than_supplier_cost_multiple, if: :need_price_validation

    # callbacks
    after_save :update_prices_columns, if: -> { saved_change_to_enabled? || saved_change_to_start_at? || saved_change_to_end_at? }

    # other macros
    delegate :name, to: :store, prefix: true
    ransacker :state, formatter: proc { |val| states[val] }

    aasm :state, column: :state, enum: true, requires_lock: true do
      state :pending, initial: true
      state :activated
      state :finished

      event :activate do
        transitions from: :pending, to: :activated
        after do
          self.update(enabled: true)
          enqueue_start_promotion_price_job
          enqueue_finish_promotion_price_job
        end
      end

      event :finish do
        transitions from: [:pending, :activated], to: :finished
        after do
          restore_sku_quantity
        end
      end
    end

    attr_accessor :need_price_validation

    # scopes
    scope :active, -> { activated_state.where("time_limited_promotions.start_at <= ? AND time_limited_promotions.end_at > ?", Time.current, Time.current) }
    scope :valid, -> { where("time_limited_promotions.end_at > ?", Time.current) }

    # class methods

    # instance methods
    def can_edit
      pending?
    end

    def update_prices_columns
      time_limited_promotion_prices.update(store_id: store_id, enabled: enabled, start_at: start_at, end_at: end_at)
    end

    def enqueue_start_promotion_price_job
      UpdateTimeLimitedPromotionPricesJob.set(wait_until: start_at).perform_later(id, "start_sku_quantity_and_reserved_quantity")
    end

    def enqueue_finish_promotion_price_job
      UpdateTimeLimitedPromotionPricesJob.set(wait_until: end_at).perform_later(id, "finish!")
    end

    def start_sku_quantity_and_reserved_quantity
      return unless (enabled && Time.current >= start_at)

      time_limited_promotion_prices.includes(:stock_keeping_unit).find_each do |promotion|
        next if promotion.quantity_updated_at.present?

        reserved_quantity = 0
        quantity = 0
        sku = promotion.stock_keeping_unit

        # 处理库存数据
        if sku.quantity > promotion.quantity
          reserved_quantity = sku.quantity - promotion.quantity
          quantity = promotion.quantity
        else
          quantity = sku.quantity
        end

        original_quantity = sku.quantity
        quantity_changed = quantity != original_quantity

        # 处理限购数据
        item = sku.item
        original_buy_quota = item.buy_quota
        original_buy_quota_days = item.buy_quota_days

        buy_quota = promotion.buy_quota
        buy_quota_days = promotion.buy_quota_days
        if original_buy_quota.positive? && original_buy_quota < buy_quota
          buy_quota = original_buy_quota
        end
        # 有产品的original_buy_quota_days为nil
        if original_buy_quota_days&.positive? && original_buy_quota_days < buy_quota_days
          buy_quota_days = original_buy_quota_days
        end

        opt = MagicBean::OperationRecord.new(
          operatable: sku.item,
          store_id: sku.store_id,
          channel: :admin,
          content: "SKU (#{sku.no}) 库存从 #{original_quantity} 改为限时优惠库存 #{quantity}，原价库存 #{reserved_quantity}，限购数改为#{buy_quota}，限购周期改为#{buy_quota_days}"
        )

        # FIXME: 这里应该是有问题，item（id: 17812）在限时优惠中，sku(id：20129)的in_time_limited_promotion为true, 但item的in_time_limited_promotion为false
        ActiveRecord::Base.transaction do
          promotion.update(
            reserved_quantity: reserved_quantity, original_buy_quota: original_buy_quota,
            original_buy_quota_days: original_buy_quota_days, quantity_updated_at: Time.current
          )
          sku.update(quantity: quantity)
          sku.in_time_limited_promotion = true
          item.update_columns(buy_quota: buy_quota, buy_quota_days: buy_quota_days)
          opt.save if quantity_changed
        end
      end
    end

    def restore_sku_quantity
      return if Time.current < start_at

      time_limited_promotion_prices.includes(:stock_keeping_unit).find_each do |promotion|
        sku = promotion.stock_keeping_unit
        item = sku.item
        original_quantity = sku.quantity
        quantity = sku.quantity + promotion.reserved_quantity.to_i
        quantity_changed = quantity != original_quantity

        opt = MagicBean::OperationRecord.new(
          operatable: sku.item,
          store_id: sku.store_id,
          channel: :admin,
          content: "SKU (#{sku.no}) 限时优惠库存从 #{original_quantity} 改为原价库存 #{quantity}，限购数改为#{promotion.original_buy_quota}，限购周期改为#{promotion.original_buy_quota_days}"
        )
        if sku.update(quantity: quantity)
          sku.in_time_limited_promotion.clear
          opt.save if quantity_changed
        end

        item.update_columns(buy_quota: promotion.original_buy_quota, buy_quota_days: promotion.original_buy_quota_days)
      end

      # 正式环境出现限时优惠活动完成，sku的in_time_limited_promotion为false，但item的in_time_limited_promotion仍为true
      # update enabled会触发更新time_limited_promotion_price，从而触发update_item_price方法，update_item_price会查询sku的限时优惠状态
      self.update(enabled: false)
    end

    def all_promotion_price_greater_than_supplier_cost_multiple
      if time_limited_promotion_prices.map(&:check_price_less_than_supplier_cost_multiple).any?
        self.errors.add(:base, "限时优惠价不得低于进货价的倍数")
      end
    end

    def import_from_excel_and_notify(file_url, admin_user_id)
      admin_user = MagicBean::AdminUser.find admin_user_id
      error_messages = import_data_from_excel(file_url, admin_user)
      ItemMailer.notify_basic_import(admin_user.email, error_messages).deliver_later
      Aws::CustomOss.delete_file(file_url)
    end

    def import_data_from_excel(file_url, admin_user)
      xlsx, unsupported_file_message = self.class.try_load_remote_file(file_url)

      if xlsx.nil? && unsupported_file_message.present?
        return [unsupported_file_message]
      end

      unless pending_state?
        return ["只能更新未开始的限时优惠活动"]
      end

      error_messages = []
      result = xlsx.sheet(0).parse(headers: true)

      # 跳过两行表头
      skip_row_offset = 2
      result[skip_row_offset..-1].each.with_index(skip_row_offset + 1) do |row, idx|
        store_id = row["store_id"]
        no = row["no"]
        price_in_cent = row["price_in_cent"].to_i
        quantity = row["quantity"].to_i
        buy_quota = row["buy_quota"].to_i
        buy_quota_days = row["buy_quota_days"].to_i
        position = row["position"]

        break if store_id.blank? && no.blank?

        if store_id.blank?
          error_messages << "第#{idx}行：门店ID不能为空"
          next
        end

        if no.blank?
          error_messages << "第#{idx}行：SKU货号不能为空"
          next
        end

        unless price_in_cent.positive? && quantity.positive?
          error_messages << "第#{idx}行：优惠价和数量必填且大于零"
          next
        end

        sku = MagicBean::StockKeepingUnit.find_by(store_id: store_id, no: no)

        if sku.blank?
          error_messages << "第#{idx}行：没有找到SKU货号【#{no}】"
          next
        end

        if time_limited_promotion_prices.exists?(stock_keeping_unit_id: sku.id)
          error_messages << "第#{idx}行：已设置SKU货号【#{no}】的限时优惠，不能重复设置"
          next
        end

        promotion_price = MagicBean::TimeLimitedPromotionPrice.new(
          time_limited_promotion_id: id, stock_keeping_unit_id: sku.id,
          price_in_cent: price_in_cent, quantity: quantity,
          buy_quota: buy_quota, buy_quota_days: buy_quota_days,
          position: position
        )

        if admin_user.can_not_force_update_sku_price? && promotion_price.check_price_less_than_supplier_cost_multiple
          error_messages << "第#{idx}行：SKU优惠价不能低于进货价的指定倍数"
          next
        end

        if !promotion_price.save
          error_messages << "第#{idx}行：#{promotion_price.errors.full_messages.join(", ")}"
        end
      end

      error_messages
    end
  end
end
