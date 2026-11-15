# frozen_string_literal: true
module MagicBean
  class GrouponActivity < ApplicationRecord
    include PriceConvertConcern

    # scope
    scope :published, -> { where(enabled: true) }
    scope :going, -> { where(arel_table[:start_at].lteq(Time.current).and(arel_table[:end_at].gt(Time.current))) }
    scope :pending, -> { where(arel_table[:start_at].gteq(Time.current)) }
    scope :ended, -> { where(arel_table[:end_at]).lteq(Time.current) }
    scope :active, -> { published.where(arel_table[:end_at].gt(Time.current)) }

    # constants

    # attr related macros
    convert_price_to_yuan :price_in_cent

    enum kind: {
      item: 1,
      sku: 2
    }

    enum wms_sync_type: {
      after_groupon_finished: 1,
      after_activity_ended: 2,
      not_sync: 3 # 虚拟商品不同步订单
    }

    # association macros
    belongs_to :item
    belongs_to :store
    has_many :sku_groupons, dependent: :destroy
    has_many :groupons
    has_many :groupon_orders
    has_many :users, through: :groupon_orders

    # validation macros
    validates_presence_of :kind, :start_at, :end_at
    validates_numericality_of :user_count, greater_than_or_equal_to: 2

    validate :check_price_in_cent_valid, :check_only_one_groupon_activity_in_a_period, :check_item_delivery_type
    before_validation :set_store_id

    # callbacks
    # 统一创建sku_gorupons，方便前端处理
    after_create :create_sku_groupons, if: -> { item? }
    after_update :update_sku_groupons_enabled, if: -> { item? && (saved_change_to_price_in_cent? || saved_change_to_enabled?) }

    # other macros
    delegate :title, :price_range, to: :item, prefix: true, allow_nil: true

    accepts_nested_attributes_for :sku_groupons, allow_destroy: true

    def publish
      update(enabled: true) unless enabled
    end

    def unpublish
      update(enabled: false) if enabled
    end

    def price_range
      item? ? "$ #{price_in_yuan}" : sku_groupon_price_range
    end

    def sku_groupon_price_range
      min_price == max_price ? "$ #{min_price}" : "$ #{min_price} ~ $ #{max_price}"
    end

    def min_price
      sku_groupons.enabled.min { |a, b| a.price_in_cent <=> b.price_in_cent }&.price_in_yuan
    end

    def max_price
      sku_groupons.enabled.max { |a, b| a.price_in_cent <=> b.price_in_cent }&.price_in_yuan
    end

    def waiting_groupons
      groupons.where(status: :waiting).order(id: :asc)
    end

    def finished_groupons
      groupons.where(status: [:finished, :free]).order(id: :asc)
    end

    def waiting_groupons_count
      waiting_groupons.count
    end

    def finished_groupons_count
      finished_groupons.count
    end

    def editable?
      start_at > Time.current
    end

    private

    def check_price_in_cent_valid
      if item? && price_in_cent.to_i <= 0
        errors.add(:base, "拼团活动价格必须大于0")
      elsif sku? && sku_groupons.map(&:enabled).exclude?(true)
        errors.add(:base, "当类型为SKU时，至少需有一个SKU参与拼团")
      end
    end

    def check_only_one_groupon_activity_in_a_period
      if enabled? && exists_other_activity?
        errors.add(:base, "同个商品在某个时间段内只能有一个发布的拼团活动")
      end
    end

    def exists_other_activity?
      MagicBean::GrouponActivity.published
        .where.not(id: id)
        .where(":start_at < end_at AND :end_at > start_at", { start_at: start_at, end_at: end_at }).exists?(item_id: item_id)
    end

    def check_item_delivery_type
      errors.add(:base, "虚拟商品和不同步WMS必须同时选择") if (item.delivery_type == ["virtual_delivery"] && !not_sync?) || (item.delivery_type != ["virtual_delivery"] && not_sync?)
    end

    def create_sku_groupons
      item.stock_keeping_units.each do |sku|
        MagicBean::SkuGroupon.create(groupon_activity_id: id, item_id: item.id, stock_keeping_unit_id: sku.id, price_in_cent: price_in_cent, enabled: enabled)
      end
    end

    def update_sku_groupons_enabled
      sku_groupons.update_all(price_in_cent: price_in_cent, enabled: enabled)
    end

    def set_store_id
      self.store_id = item&.store_id if self.store_id.blank?
    end
  end
end
