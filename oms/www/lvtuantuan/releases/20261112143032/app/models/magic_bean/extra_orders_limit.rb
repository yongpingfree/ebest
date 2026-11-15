# frozen_string_literal: true

class MagicBean::ExtraOrdersLimit < ApplicationRecord
  include PriceConvertConcern

  convert_price_to_yuan :order_amount_in_cent

  validates_presence_of :order_amount_in_cent, :delivery_date, :begin_at, :extra_merchant_delivery_orders_limit, :extra_merchant_delivery_total_orders_limit

  validates_uniqueness_of :delivery_date, scope: :store_id

  belongs_to :store

  after_save :save_to_redis
  after_destroy :reset_limit_in_redis

  scope :active, -> { where("begin_at <= ?", Time.current) }
  scope :valid, -> { where("delivery_date >= ?", Date.current) }

  def save_to_redis
    return unless saved_changes?
    reset_limit_in_redis
  end

  def reset_limit_in_redis
    limits = self.class.valid.map do |limit|
      {
        order_amount_in_cent: limit.order_amount_in_cent,
        delivery_date: limit.delivery_date,
        begin_at: limit.begin_at,
        extra_merchant_delivery_orders_limit: limit.extra_merchant_delivery_orders_limit,
        extra_merchant_delivery_total_orders_limit: limit.extra_merchant_delivery_total_orders_limit,
        store_id: limit.store_id
      }
    end

    Rails.cache.redis.set "extra_orders_limits", limits.to_json
  end

  def self.active_limit_from_redis(store_id, date, order_amount_in_cent = nil)
    limits_string = Rails.cache.redis.get "extra_orders_limits"
    return {} if limits_string.blank?
    limits = JSON.parse limits_string
    limits.select! { |limit| limit["begin_at"].in_time_zone <= Time.current && limit["store_id"] == store_id && limit["delivery_date"] == date.to_s }
    limits.select! { |limit| limit["order_amount_in_cent"] <= order_amount_in_cent } if order_amount_in_cent.present?
    limits.first || {}
  end
end
