# frozen_string_literal: true

class MagicBean::SameDayDeliveryCartItem < ApplicationRecord
  # scope

  # constants
  MAX_SHOPPING_CART_ITEMS_COUNT_PER_STORE = 100

  enum source_page_name: {
    home: 1,
    banner: 2,
    custom_page: 3,
    category: 4,
    item_like: 5,
    item_search: 6,
    order_list: 7,
    recommend_items: 8,
    preferential_pool: 9,
    auction_activity: 10,
    user_history: 11,
    hot_sell_list: 12 # 热卖榜
  }

  enum source_channel: {
    mini_program: 1,
    app: 2,
    web: 3
  }

  # attr related macros
  acts_as_paranoid

  # association macros
  belongs_to :same_day_delivery_cart
  belongs_to :stock_keeping_unit
  belongs_to :store

  # validation macros
  validates :stock_keeping_unit_id, presence: true, uniqueness: { scope: :same_day_delivery_cart_id }
  validate :check_item_type, :check_buy_quota, :validate_inventory, :check_item_listing_type
  validate :check_shopping_cart_items_per_store, on: :create
  before_validation :reset_columns

  # callbacks

  # other macros
  delegate :buy_quota, :item, to: :stock_keeping_unit
  delegate :user, to: :same_day_delivery_cart

  def to_order_item_json(item_price = nil, current_user = nil)
    custom_quantity = quantity.positive? ? quantity : 1
    custom_price_in_cent = [item_price, stock_keeping_unit.final_price(custom_quantity).first].compact.min
    is_new_user = current_user ? current_user.new_user : false
    new_user_price = false
    new_user_item_error = nil
    if is_new_user
      custom_price_in_cent = [custom_price_in_cent, stock_keeping_unit.new_user_price_in_cent].compact.min
      # 只有当价格使用了新人价，才需要判断限购
      if custom_price_in_cent == stock_keeping_unit.new_user_price_in_cent
        new_user_price = true
        new_user_item_error = "#{stock_keeping_unit.human_title} 新用户限购 #{stock_keeping_unit.new_user_buy_quota} 件" if stock_keeping_unit.new_user_buy_quota_invalid?(quantity, current_user)
      end
    end

    [{
       stock_keeping_unit_id: stock_keeping_unit_id,
       quantity: quantity.positive? ? quantity : 1,
       weight_in_gram: stock_keeping_unit.weight_in_gram,
       price_in_cent: custom_price_in_cent,
       strikethrough_price_in_cent: stock_keeping_unit.strikethrough_price_in_cent || custom_price_in_cent,
       title: stock_keeping_unit.title.presence || stock_keeping_unit.title_zh_cn, # 只有简体中文是必填，这里需要避免为空
       short_title: stock_keeping_unit.short_title,
       properties_text: stock_keeping_unit.properties_text,
       image: stock_keeping_unit.cover,
       item_id: stock_keeping_unit.item_id,
       sku_type: stock_keeping_unit.item_type,
       is_new_user_price: new_user_price,
       source_page_name: source_page_name,
       source_custom_list_id: source_custom_list_id,
       source_extra_hash: source_extra_hash,
       source_channel: source_channel,
       not_eligible_for_free_gift: stock_keeping_unit.item_not_eligible_for_free_gift,
       is_box_regulation: stock_keeping_unit.is_box_regulation
     }, new_user_item_error]
  end

  private

  def check_buy_quota
    return if buy_quota.zero?
    bought_quantity = if stock_keeping_unit.item.buy_quota_days.zero?
                        MagicBean::OrderItem.where(order: user.orders.effective)
                      else
                        current_time = Time.current
                        MagicBean::OrderItem.where(order: user.orders.effective.where(created_at: (current_time - stock_keeping_unit.item.buy_quota_days.days)..current_time))
                      end.where(item: stock_keeping_unit.item).sum(:quantity)
    shopping_cart_items_quantity = quantity + user.same_day_delivery_cart_items.where(stock_keeping_unit_id: stock_keeping_unit.item.stock_keeping_units.ids - [stock_keeping_unit_id]).sum(:quantity)
    errors[:base] << "该商品累计购买不能超过#{buy_quota}件" if bought_quantity + shopping_cart_items_quantity > buy_quota
  end

  def check_item_type
    errors[:base] << " #{stock_keeping_unit.human_title} 非当日达产品不可加入购物车！" unless item.same_day_delivery?
  end

  def validate_inventory
    errors[:base] << "加入购物车数量不得超过商品库存" if exceed_inventory?
  end

  def check_item_listing_type
    errors[:base] << " #{stock_keeping_unit.human_title} 已停售！" unless !item.pending? && stock_keeping_unit.on_sale?
  end

  def exceed_inventory?
    quantity > stock_keeping_unit.quantity
  end

  def reset_columns
    self.store_id = stock_keeping_unit.store_id
    self.quantity = 1 unless quantity.positive?
  end

  def check_shopping_cart_items_per_store
    if user.same_day_delivery_cart_items.where(store_id: store_id).count > MAX_SHOPPING_CART_ITEMS_COUNT_PER_STORE
      errors[:base] << "每个门店购物车最多只能添加 #{MAX_SHOPPING_CART_ITEMS_COUNT_PER_STORE} 个商品（含已失效商品）"
    end
  end
end
