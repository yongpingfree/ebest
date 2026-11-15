# frozen_string_literal: true
module MagicBean
  class GiftActivity < ApplicationRecord

    # scope
    scope :active, -> { enabled.where(arel_table[:end_at].gt(Time.current).and(arel_table[:start_at].lt(Time.current))) }

    # constants

    # attr related macros
    attr_accessor :matched_rule, :gift_sku_errors

    enum status: {
      enabled: 1,
      disabled: 2
    }

    # association macros
    has_many :orders
    belongs_to :store

    # validation macros
    validates_presence_of :start_at, :end_at, :rules
    validate :check_rules_valid, :check_only_one_active_gift_activity_in_a_period

    # callbacks
    before_save :sort_rules

    # other macros

    def set_matched_rule(order, gift_sku_ids = [], gift_price_gradient = nil)
      self.gift_sku_errors = []
      # 把order.order_items.to_a, 然后将not_eligible_for_free_gift为false的数据过滤出来      
      active_amount_in_yuan = order.eligible_for_free_gift_amount_in_yuan_num

      self.matched_rule = rules.find do |rule|
        # 如果gift_price_gradient不为nil, 则先比对price_gradient; 否则则比对active_amount
        if gift_price_gradient.present?
          next false if rule["price_gradient"] != gift_price_gradient.to_f
        else
          next false if rule["price_gradient"] > active_amount_in_yuan
        end

        rule["stock_keeping_units"] = (rule["skus"] || []).map do |sku_obj|
          sku = MagicBean::StockKeepingUnit.find_by(id: sku_obj["sku_id"])

          next if sku_obj["not_support_express"] && order.express?

          next if sku.blank?

          if should_hide_sku?(sku, order.delivery_type)
            if gift_sku_ids.include?(sku.id)
              gift_sku_errors << I18n.t("error.gift_activity.unavaliable", title: sku.human_title)
            elsif sku_exclude_delivery_type(sku, order.delivery_type)
              gift_sku_errors << I18n.t(
                                   "error.gift_activity.unsupported_delivery_type",
                                   title: sku.human_title,
                                   delivery_type: I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{order.delivery_type}")
                                 )
            end
            next
          end

          BeansApp::API::Entities::SimpleStockKeepingUnit.new(sku).as_json.merge({
            quantity: sku_obj["quantity"]
          })
        end

        next false if rule["stock_keeping_units"].compact.empty?

        rule
      end
    end

    # rules: [{"price_gradient"=>1, "skus"=>[{"sku_id"=>1, "quantity"=>1}]}, {"price_gradient"=>2, "skus"=>[{"sku_id"=>2, "quantity"=>2}]}]
    def gifts_properties_for(order, gift_sku_ids, gift_coupon_template_id = nil, gift_price_gradient = nil)
      set_matched_rule(order, gift_sku_ids, gift_price_gradient)

      unless matched_rule
        order.errors.add(:base, I18n.t("error.gift_activity.not_meet_the_conditions"))
        return
      end

      order_items_attributes = []

      # 如果优惠券和赠品只能选一样，这里要返回错误
      if !matched_rule["coupon_and_skus_all_give"] && gift_sku_ids.size.positive? && gift_coupon_template_id.present?
        order.errors.add(:base, I18n.t("error.gift_activity.at_most_one_can_be_chosen"))
        return
      end

      # 如果不是 all_give，则赠品只能选一样
      if !matched_rule["all_give"] && gift_sku_ids.size > 1
        order.errors.add(:base, I18n.t("error.gift_activity.select_one_gift_only"))
        return
      end

      allow_sku_ids = matched_rule["skus"].map { |sku| sku["sku_id"].to_i }

      if (gift_sku_ids.map(&:to_i) - allow_sku_ids).present?
        # 优化页面的交互，只在提交订单的时候提示赠品错误
        # 不同级别赠品可以设置相同商品，所以进到这个条件后再判断是否有过期商品
        if !order.is_preview
          if gift_sku_errors.present?
            order.errors.add(:base, gift_sku_errors.uniq.join("， "))
          else
            order.errors.add(:base, I18n.t("error.gift_activity.choose_again"))
          end
        end

        return
      end

      gift_sku_ids.each do |sku_id|
        quantity = matched_rule["skus"].find do |sku_obj|
          sku_obj["sku_id"] == sku_id
        end["quantity"]

        stock_keeping_unit = MagicBean::StockKeepingUnit.includes(:item).find_by(id: sku_id)

        order_item_attribute = stock_keeping_unit.to_order_item_json(quantity, nil).first
        order_item_attribute["price_in_yuan"] = stock_keeping_unit.price_in_yuan
        order_item_attribute["no"] = stock_keeping_unit.no
        order_item_attribute["storage_method"] = stock_keeping_unit.storage_method
        order_item_attribute["gift_card_enabled"] = stock_keeping_unit.item_gift_card_enabled
        order_item_attribute["coupon_enabled"] = stock_keeping_unit.item_coupon_enabled
        order_item_attribute["free_shipping"] = stock_keeping_unit.item_free_shipping

        order_items_attributes << order_item_attribute
      end

      order_items_attributes
    end

    def human_rules(delivery_type = nil, item_amount_in_yuan = 0)
      target_rules = []
      rules.each do |rule|
        price_gradient_format = rule["price_gradient"] == rule["price_gradient"].to_i ? rule["price_gradient"].to_i : rule["price_gradient"]
        all_give_text = rule["all_give"] ? " (#{I18n.t("grape.orders.all_give_text")})" : nil
        coupon_and_skus_all_give_text = rule["coupon_and_skus_all_give"] ? I18n.t("grape.orders.coupon_and_skus_all_give") : "/"
        if rule["price_gradient"] <= item_amount_in_yuan
          rule["notice_text"] = "#{I18n.t("grape.orders.gift_notice_text", amount: price_gradient_format, coupon_and_skus_all_give: coupon_and_skus_all_give_text)}#{all_give_text}"
          # 允许多个规则命中
          rule["is_match"] = true
        else
          still_need_price = (rule["price_gradient"] - item_amount_in_yuan).round(2)
          still_need_price_format = still_need_price == still_need_price.to_i ? still_need_price.to_i : still_need_price
          rule["notice_text"] = I18n.t("grape.orders.gift_options_notice_text", amount: price_gradient_format, still_need_amount: still_need_price_format)
          rule["is_match"] = false
        end

        delete_skus = []
        rule["skus"] = rule["skus"].to_a
        rule["skus"].each do |sku|
          stock_keeping_unit = MagicBean::StockKeepingUnit.find_by(id: sku["sku_id"])
          if (delivery_type.to_s == "express" && sku["not_support_express"]) || stock_keeping_unit.blank? || should_hide_sku?(stock_keeping_unit, delivery_type)
            delete_skus << sku
            next
          end
          sku["title"] = "#{stock_keeping_unit.title} - #{stock_keeping_unit.properties_text}"
          sku["price_in_yuan"] = stock_keeping_unit.price_in_yuan
          sku["image"] = stock_keeping_unit.cover
          sku["item_id"] = stock_keeping_unit.item_id
        end

        rule["skus"] -= delete_skus

        coupon_template = MagicBean::CouponTemplate.find_by(id: rule["coupon_template_id"])
        rule["coupon_template"] = {}
        if coupon_template
          rule["coupon_template"]["id"] = coupon_template.id
          rule["coupon_template"]["title"] = coupon_template.title
          rule["coupon_template"]["kind"] = coupon_template.kind
          rule["coupon_template"]["discount"] = coupon_template.discount
          rule["coupon_template"]["denominations_in_cent"] = coupon_template.denominations_in_cent
          rule["coupon_template"]["denominations_in_yuan"] = coupon_template.denominations_in_yuan
          rule["coupon_template"]["start_at"] = coupon_template.start_at
          rule["coupon_template"]["end_at"] = coupon_template.end_at
          # NOTE: app 端用错字段，alias 一个 expired_at。App 端修复后可删掉
          rule["coupon_template"]["expired_at"] = coupon_template.end_at
          rule["coupon_template"]["channel"] = coupon_template.channel
          rule["coupon_template"]["store_name"] = coupon_template.store&.name
        end

        if rule["skus"].present? || rule["coupon_template"].present?
          target_rules << rule
        end
      end

      target_rules
    end

    private

    def sort_rules
      # 先排序每个规则下的商品
      self.rules.each do |rule|
        rule["skus"] = (rule["skus"] || []).sort_by { |sku| sku["position"].to_i }
      end
      self.rules = self.rules.sort_by { |rule| -rule["price_gradient"] }
    end

    def check_rules_valid
      rules.each do |rule|
        errors.add(:base, "SKU或优惠券必填一个") if rule["skus"].blank? && rule["coupon_template_id"].blank?
        sku_ids = rule["skus"]&.pluck("sku_id")
        errors.add(:base, "同个价格梯度的商品不可重复") unless sku_ids&.size == sku_ids&.uniq&.size
        rule["skus"].to_a.each do |sku|
          errors.add(:base, "商品必填") unless sku["sku_id"]
        end
      end
    end

    def check_only_one_active_gift_activity_in_a_period
      if enabled? && exists_other_activity?
        errors.add(:base, "同个门店同个时间段内只能有一个启用的赠品活动")
      end
    end

    def exists_other_activity?
      MagicBean::GiftActivity.enabled
        .where.not(id: id)
        .where(store_id: store_id)
        .where(":start_at < end_at AND :end_at > start_at", { start_at: start_at, end_at: end_at }).exists?
    end

    def should_hide_sku?(sku, delivery_type)
      # 管理后台也要进到这个方法内，只在订单页才需要判断sku库存等条件
      delivery_type.present? && (sku_not_on_sale_or_out_of_stock(sku) || sku_exclude_delivery_type(sku, delivery_type))
    end

    def sku_not_on_sale_or_out_of_stock(sku)
      sku.quantity.zero? || !sku.is_on_sale?
    end

    def sku_exclude_delivery_type(sku, delivery_type)
      sku.item.delivery_type.exclude?(delivery_type)
    end
  end
end
