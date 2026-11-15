# frozen_string_literal: true

module MagicBean
  class PreferentialPool < ApplicationRecord
    include PriceConvertConcern

    # scope
    scope :active, -> { where("enabled = true AND end_at >= :time AND start_at <= :time", { time: Time.current }) }
    scope :enabled, -> { where(enabled: true) }

    # attr related macros
    translates :title
    globalize_accessors attributes: [:title]

    enum kind: {
      discount: 1,
      reduction: 2,
      coupon_template: 3,
      gift: 4
    }

    enum threshold_kind: {
      amount_threshold: 1,
      quantity_threshold: 2
    }

    convert_price_to_yuan :at_least_amount_in_cent

    # validation macros
    validates_presence_of :title_zh_cn, :start_at, :end_at
    validate :check_start_at_and_end_at_valid
    validates_presence_of :at_least_amount_in_cent, if: -> { amount_threshold? }
    validates_presence_of :at_least_quantity, if: -> { quantity_threshold? }
    validate :check_preferences
    validate :check_sku_used?, if: -> { enabled? }

    # callbacks
    before_create :set_title_i18n

    def self.active_for_order(order)
      order_item_hash = {}
      order.order_items.to_a.each do |order_item|
        order_item_hash["#{order_item.stock_keeping_unit_id}"] = { amount_in_cent: order_item.amount_in_cent, quantity: order_item.quantity }
      end

      active_pools = {}

      MagicBean::PreferentialPool.active.where(store_id: [nil, order.store_id]).each do |pool|
        # 先找到订单中满足该优惠池的所有订单项
        active_sku_ids = order_item_hash.keys.map do |key|
          key if pool.sku_ids.include?(key.to_i)
        end.compact

        next if active_sku_ids.blank?

        # 然后计算是否满足优惠池门槛
        if (pool.amount_threshold? && active_sku_ids.map { |sku_id| order_item_hash[sku_id][:amount_in_cent] }.sum >= pool.at_least_amount_in_cent) || (pool.quantity_threshold? && active_sku_ids.map { |sku_id| order_item_hash[sku_id][:quantity] }.sum >= pool.at_least_quantity)
          active_pools[pool.kind] ||= []
          target_pool = pool.as_json(except: [:created_at, :updated_at])

          if pool.discount? || pool.reduction?
            order_item_amount_sum = active_sku_ids.map { |sku_id| order_item_hash[sku_id][:amount_in_cent] }.sum
            target_pool["discount_amount_in_cent"] =
              if pool.discount?
                # discount为9时，1 - discount / 10.0 = 0.09999
                (order_item_amount_sum * (10 - pool.preferences["discount"]) / 10.0).floor
              elsif pool.reduction?
                [pool.preferences["denominations_in_cent"], order_item_amount_sum].min
              end
            target_pool["discount_amount_in_yuan"] = ActiveSupport::NumberHelper.number_to_currency(target_pool["discount_amount_in_cent"].to_i / 100.0, format: "%n", delimiter: "")

            # 计算每个order_item优惠池优惠后的pool_price_in_cent
            order.order_items.each do |order_item|
              next if pool.sku_ids.exclude?(order_item.stock_keeping_unit_id)
              order_item.pool_price_in_cent =
                if pool.discount?
                  (order_item.price_in_cent * pool.preferences["discount"] / 10.0).ceil
                elsif pool.reduction?
                  # 满减额度可能大于订单项总金额，所以这里取二者较小值
                  order_item.price_in_cent - (order_item.price_in_cent.to_f / order_item_amount_sum * target_pool["discount_amount_in_cent"]).floor
                end
            end
          end

          active_pools[pool.kind] << target_pool
        end
      end

      active_pools
    end

    def self.active_for_item(item)
      item_sku_ids = item.stock_keeping_units.pluck(:id)
      target_pool = {}
      MagicBean::PreferentialPool.active.where(store_id: [nil, item.store_id]).each do |pool|
        if (pool.sku_ids & item_sku_ids).present?
          target_pool = pool.as_json(except: [:created_at, :updated_at])
          target_pool["at_least_amount_in_yuan"] = pool.at_least_amount_in_yuan
          target_pool["skus"] = pool.human_skus
          if pool.coupon_template?
            target_pool["preferences_coupon_templates"] = pool.preferences_coupon_templates
          elsif pool.gift?
            target_pool["preferences_skus"] = pool.human_preferences_skus
          end

          break
        end
      end
      target_pool
    end

    def self.increase_quantity_of_free_gift(order)
      order.pool_gifts_properties.each do |elem|
        pool = MagicBean::PreferentialPool.find_by id: elem["preferential_pool_id"]

        next if pool.nil?

        pool.preferences["skus"] = pool.preferences["skus"].map do |sku|
          if sku["sku_id"] == elem["stock_keeping_unit_id"]
            # 把订单中赠送的赠品数累加到优惠池对应的 sku 上
            current_given_quantity = sku["given_quantity"].to_i
            sku["given_quantity"] = current_given_quantity + elem["quantity"]

            # 如果赠送数量超过上限，停用优惠池并发送通知邮件
            if sku["given_quantity"] >= sku["quantity_limit"]
              pool.enabled = false
              db_sku = MagicBean::StockKeepingUnit.find sku["sku_id"]
              messages = { out_of_stock_messages: ["赠品【#{db_sku.human_title}】赠送数量已到达/超过上限"] }
              emails = pool.preferences["notification_emails"]
              OrderMailer.with(order_id: order.id, sku_messages: messages, emails: emails.split(/[;；]/)).sku_notify.deliver_later if emails.present?
            end
          end

          sku
        end

        pool.save
      end
    end

    def self.decrease_quantity_of_free_gift(order)
      order.pool_gifts_properties.each do |elem|
        pool = MagicBean::PreferentialPool.find_by id: elem["preferential_pool_id"]

        next if pool.nil?

        pool.preferences["skus"] = pool.preferences["skus"].map do |sku|
          if sku["sku_id"] == elem["stock_keeping_unit_id"]
            # 把订单中赠送的赠品数从优惠池对应的sku中减去
            current_given_quantity = sku["given_quantity"].to_i
            sku["given_quantity"] = current_given_quantity - elem["quantity"]
          end

          sku
        end

        pool.save
      end
    end

    def skus
      MagicBean::StockKeepingUnit.includes(:item).where(id: sku_ids)
    end

    def human_skus
      skus.map do |sku|
        next unless sku.is_on_sale?
        final_price = sku.final_price(1)
        {
          id: sku.id,
          title: sku.human_title,
          item_id: sku.item_id,
          image: sku.cover,
          price_in_cent: final_price.first,
          price_in_yuan: final_price.last,
          quantity: sku.quantity,
        }
      end.compact
    end

    def preferences_coupon_templates
      if preferences["coupon_template_ids"].blank?
        []
      else
        MagicBean::CouponTemplate.where(id: preferences["coupon_template_ids"])
      end
    end

    def human_preferences_skus
      if preferences["skus"].blank?
        []
      else
        delete_skus = []
        preferences["skus"] = preferences["skus"].to_a
        preferences["skus"].each do |sku|
          stock_keeping_unit = MagicBean::StockKeepingUnit.find_by(id: sku["sku_id"])
          # 把不存在的过滤掉
          if stock_keeping_unit.blank?
            delete_skus << sku
            next
          end
          sku["title"] = stock_keeping_unit.human_title
          sku["price_in_yuan"] = stock_keeping_unit.price_in_yuan
          sku["image"] = stock_keeping_unit.cover
          sku["sku_quantity"] = stock_keeping_unit.quantity
          sku["item_id"] = stock_keeping_unit.item_id
        end

        preferences["skus"] -= delete_skus
      end
    end

    private

    def check_start_at_and_end_at_valid
      errors.add(:base, I18n.t("errors.messages.start_at_can_not_later_than_end_at")) if start_at && end_at && start_at > end_at
    end

    def check_preferences
      return errors.add(:base, "优惠设置内容必填") if preferences.blank?
      if discount?
        errors.add(:base, "折扣不能为空且要大于0或小于10") if preferences["discount"].blank? || !preferences["discount"].positive? || preferences["discount"] >= 10
      elsif reduction?
        return errors.add(:base, "满减金额不能为空且要大于0") if preferences["denominations_in_yuan"].blank? || !preferences["denominations_in_yuan"].positive?
        preferences["denominations_in_cent"] = (preferences["denominations_in_yuan"].to_f * 100).round
      elsif coupon_template?
        errors.add(:base, "优惠券不能为空") if preferences["coupon_template_ids"].blank?
        errors.add(:base, "不能关联随机满减券") if preferences_coupon_templates.exists?(kind: :random_reduction)
      elsif gift?
        if [preferences["notification_quantity"], preferences["notification_emails"], preferences["skus"]].select(&:blank?).present?
          errors.add(:base, "报警数量、接收邮箱、SKU不能为空")
        elsif preferences["skus"].select { |sku| sku["sku_id"].blank? || !sku["quantity"].to_i.positive? || !sku["quantity_limit"].to_i.positive? }.present?
          errors.add(:base, "SKU商品和数量、赠品数量上限不能为空，且数量需大于0")
        end
      end
    end

    def check_sku_used?
      # 判断在有效期内，是否有其他优惠池也有相同item
      enabled_sku_ids = MagicBean::PreferentialPool.enabled.where.not(id: self.id).where(":start_at < end_at AND :end_at > start_at", start_at: start_at, end_at: end_at).pluck(:sku_ids).flatten
      return if enabled_sku_ids.blank?
      enabled_item_ids = MagicBean::StockKeepingUnit.where(id: enabled_sku_ids).pluck(:item_id)

      used_sku_titles = []

      MagicBean::StockKeepingUnit.includes(:item).where(id: sku_ids).each do |sku|
        used_sku_titles << "#{sku.human_title}(#{sku.no})" if sku.item_id.in? enabled_item_ids
      end

      errors.add(:base, "一个产品下多个SKU在同个时间段只能设置一个优惠池，#{used_sku_titles.join(", ")} 所属产品已设置优惠池") if used_sku_titles.present?
    end

    def set_title_i18n
      self.title_zh_tw = Ropencc.conv("s2tw.json", title_zh_cn) if title_zh_tw.blank?
      self.title_en = EasyTranslate.translate(title_zh_cn, from: :"zh-CN", to: :en) if title_en.blank?
    end
  end
end
