# frozen_string_literal: true
module MagicBean
  class StockKeepingUnit < ApplicationRecord
    include PriceConvertConcern
    include SkuImportConcern
    include ResourceUrlValidationConcern
    include Redis::Objects

    # scope
    scope :normal, -> { joins(:item).where(items: { item_type: "normal" }) }
    scope :on_sale, -> { where(on_sale: true) }
    # constants
    PROPERTIES_SEPARATOR = ";"
    PID_VID_SEPARATOR = ":"
    RESOURCE_URL_COLUMNS = [:image]

    # attr related macros
    enum marketing_mode: {
      self_support: 1,
      consign_for_sale: 2,
      platform: 3
    }

    delegate :category, :parent_category, :parent_category_id, :title, :short_title, :item_type, :delivery_type, :buy_quota, :brand_name, :listing_type, :sub_title, :is_virtual, :title_zh_cn, :title_en, :storage_method, :delivery_weekdays, :freight_type, :leader, :gift_only, :ae_drop_shipper, :storage_method, to: :item
    delegate :on_sale?, :show_on_sale_soon_tag, :not_eligible_for_free_gift, :coupon_enabled, :gift_card_enabled, :free_shipping, to: :item, prefix: true
    delegate :top_left_corner_tag_image, to: :item
    delegate :name, to: :store, prefix: true
    delegate :peti_store?, to: :store
    delegate :name, :cost_in_yuan, :cost_in_cent, :include_gst, :gst_amount, to: :newest_supplier, prefix: true, allow_nil: true

    convert_price_to_yuan :price_in_cent, :cost_price_in_cent, :strikethrough_price_in_cent, :discount_price_in_cent, :new_user_price_in_cent, :shopline_price_in_cent, :ae_price_in_cent

    # association macros
    belongs_to :item
    belongs_to :store
    has_many :comments, as: :commentable
    has_many :order_items, dependent: :restrict_with_error
    has_many :orders, through: :order_items
    has_many :after_sales, through: :order_items
    has_many :sku_groupons
    has_many :suppliers, dependent: :destroy
    has_many :sku_in_stock_notices, dependent: :destroy
    has_many :shopping_cart_items, dependent: :destroy
    has_one :newest_supplier, -> { order(updated_at: :desc) }, class_name: "MagicBean::Supplier", foreign_key: :stock_keeping_unit_id
    has_many :wms_inventories, class_name: "MagicBean::WmsInventory", foreign_key: :product_id
    accepts_nested_attributes_for :suppliers, allow_destroy: true

    has_many :time_limited_promotion_prices, dependent: :destroy
    has_many :time_limited_promotions, through: :time_limited_promotion_prices
    has_many :active_time_limited_promotions, -> { active.where(enabled: true) }, through: :time_limited_promotion_prices, source: :time_limited_promotion
    has_many :valid_time_limited_promotions, -> { valid }, through: :time_limited_promotion_prices, source: :time_limited_promotion

    has_many :promo_stock_keeping_units, dependent: :destroy
    has_many :live_room_skus, dependent: :destroy
    has_many :sku_valid_inventory_dates, dependent: :destroy
    has_many :sku_inventory_snapshots, dependent: :destroy
    has_one :last_monday_inventory_snapshot, -> { where(record_date: Date.current.at_beginning_of_week - 1.week) }, class_name: "MagicBean::SkuInventorySnapshot"
    has_one :shopline_sku, -> { shopline }, class_name: "MagicBean::ThirdPartySku", dependent: :destroy
    has_one :ae_sku, -> { aliexpress }, class_name: "MagicBean::ThirdPartySku", dependent: :destroy

    attr_accessor :import_skip_validation

    # validation macros
    validates_uniqueness_of :no, scope: :store_id
    validates_presence_of :no, :properties, :gst_percent
    validates_presence_of :shoppingunit, if: -> { platform? }
    validates :barcode, presence: true, if: -> { !import_skip_validation }
    validates :barcode, format: { with: /\A[0-9a-zA-Z().\-,\s]*\z/, message: I18n.t("activerecord.attributes.magic_bean/item/stock_keeping_units.errors.barcode_can_only_contains", locale: I18n.locale) }, allow_nil: true
    validates :barcode, uniqueness: { scope: :store_id }, allow_nil: true
    validates :price_in_cent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }
    validates :new_user_price_in_cent, allow_nil: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :strikethrough_price_in_cent, allow_nil: true, numericality: { greater_than: :price_in_cent, message: I18n.t("activerecord.attributes.magic_bean/item/stock_keeping_units.errors.must_greater_than_price_in_cent", locale: I18n.locale) }
    validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :new_user_buy_quota, allow_nil: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :weight_in_gram, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :length_in_cm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :height_in_cm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :width_in_cm, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999999 }
    validates :shopline_price_in_cent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }
    validates :ae_price_in_cent, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 999999999 }
    validate :properties_ids_exist
    validate :properties_ids_unique
    validate :properties_matched
    validate :check_discount_quantity_and_price
    validate :at_least_one_sku_if_item_on_sale

    # callbacks
    before_validation :reset_strikethrough_price, :set_default_value, :format_barcodes, :format_barcode, :set_shopline_and_ae_price_in_cent
    before_save :order_sku_properties, :set_groups_properties, :try_set_first_sale_time
    before_save :format_no, if: :no_changed?
    after_commit :update_item_quantity, :update_item_price_in_cent, :update_item_strikethrough_price_in_cent, :update_item_new_user_price_in_cent
    after_commit :set_valid_inventory_dates, if: -> { saved_change_to_quantity? || saved_change_to_on_sale? }
    after_commit :check_if_shopline_need_to_sync
    after_commit :enqueue_generate_aws_lambda_image_job, if: -> { image_previously_changed? }

    # other macros
    value :in_time_limited_promotion

    def properties_ids_array
      @properties_ids_array ||= if properties.blank?
        []
      else
        properties.split(PROPERTIES_SEPARATOR)
      end
    end

    def pids
      @pids ||= properties_ids_array.map { |p_v| p_v.split(PID_VID_SEPARATOR).first.to_i }
    end

    def vids_sort_by_pids
      @vids_sort_by_pids ||= properties_ids_array.map { |p_v| p_v.split(PID_VID_SEPARATOR).last.to_i }
    end

    def vids
      @vids ||= vids_sort_by_pids.sort_by { |vid| vid.to_i }
    end

    def properties_array
      MagicBean::SkuValue.includes(:translations).where(id: vids).map(&:text)
    end

    # 跨境购规格会包含括号，只返回第一个括号里面的值
    def ae_drop_ship_properties_array
      MagicBean::SkuValue.includes(:translations).where(id: vids).map do |val|
        val_text = val.text
        if val_text.match(/\(.*\)/)
          val_text[/\((.*)\)/, 1]
        else
          val_text
        end
      end
    end

    # 仅用于shopline同步, 返回英文属性
    def properties_array_order_by_vids
      order_by = ["CASE"]
      vids_sort_by_pids.each_with_index do |vid, i|
        order_by << "WHEN sku_values.id='#{vid}' THEN #{i}"
      end
      order_by << "END"

      MagicBean::SkuValue.where(id: vids_sort_by_pids).reorder(Arel.sql(order_by.join(" "))).map(&:text_en)
    end

    def properties_text
      properties_array.join(" ")
    end

    def ae_drop_shipper_properties_text
      ae_drop_ship_properties_array.join(" ")
    end

    def discount_price_active?
      discount_quantity.present? && discount_price_in_cent.present?
    end

    def display_discount_price?(qty)
      discount_price_active? && qty.to_i >= discount_quantity && discount_price_in_cent < price_in_cent
    end

    def display_promotion_price?
      in_time_limited_promotion? && current_time_limited_promotion_price.present? &&
        current_time_limited_promotion_price.price_in_cent < price_in_cent
    end

    def final_price(qty)
      @final_price ||= if display_discount_price?(qty)
                         [discount_price_in_cent, discount_price_in_yuan]
                       elsif display_promotion_price?
                         [
                           current_time_limited_promotion_price.price_in_cent,
                           current_time_limited_promotion_price.price_in_yuan
                         ]
                       else
                         [price_in_cent, price_in_yuan]
                       end
    end

    def to_order_item_json(qty, item_price = nil, sku_type = nil, is_gift = false, source_channel = nil, source_page_name = nil, source_custom_list_id = nil, source_extra_hash = nil, current_user = nil, order_item_live_top = false)
      free_gift_text = I18n.locale.to_s == "en" ? "(Free Gift)" : "（赠品）"
      custom_title = is_gift ? "#{title.presence || title_zh_cn}#{free_gift_text}" : (title.presence || title_zh_cn)
      custom_short_title = (is_gift && short_title.present?) ? "#{short_title}#{free_gift_text}" : short_title
      custom_quantity = qty.positive? ? qty : 1
      custom_price_in_cent = [item_price, final_price(custom_quantity).first].compact.min # 同时可能设置了sku数量优惠和限时优惠，以最低价格为准

      is_new_user = current_user ? current_user.new_user : false
      new_user_price = false
      new_user_item_error = nil

      if is_new_user
        custom_price_in_cent = [custom_price_in_cent, new_user_price_in_cent].compact.min
        # 只有当价格使用了新人价，才需要判断限购
        if custom_price_in_cent == new_user_price_in_cent
          new_user_price = true
          new_user_item_error = I18n.t("grape.shopping_cart_items.new_user_buy_quota", title: human_title, quota: new_user_buy_quota) if new_user_buy_quota_invalid?(qty, current_user)
        end
      end

      [{
        stock_keeping_unit_id: id,
        quantity: custom_quantity,
        weight_in_gram: weight_in_gram,
        price_in_cent: custom_price_in_cent,
        strikethrough_price_in_cent: strikethrough_price_in_cent || custom_price_in_cent, # 如果没有划线价就返回售价，方便统计原价
        title: custom_title,
        short_title: custom_short_title,
        properties_text: item.ae_drop_shipper ? ae_drop_shipper_properties_text : properties_text,
        image: cover,
        item_id: item_id,
        sku_type: sku_type || item_type,
        is_gift: is_gift,
        is_new_user_price: new_user_price,
        source_channel: source_channel,
        source_page_name: source_page_name,
        source_custom_list_id: source_custom_list_id,
        source_extra_hash: source_extra_hash,
        live_top: order_item_live_top,
        not_eligible_for_free_gift: item_not_eligible_for_free_gift,
        is_box_regulation: is_box_regulation
      }, new_user_item_error]
    end

    def cover
      image.present? ? image : item.cover
    end

    def current_sku_groupon(arg_item = nil)
      groupon_activity_id = (arg_item || item).active_groupon_activity&.id
      sku_groupons.where(groupon_activity_id: groupon_activity_id).first if groupon_activity_id
    end

    def current_time_limited_promotion_price
      @current_time_limited_promotion_price ||= time_limited_promotion_prices.active.first
    end

    def human_title
      "#{title} - #{properties_text}"
    end

    def increase_inventory!(qty)
      with_lock do
        self.increment!(:quantity, qty)
        save! # 触发callback
      end
    end

    def decrease_inventory!(qty)
      with_lock do
        self.decrement!(:quantity, qty)
        save! # 触发callback
      end
    end

    def category_id
      category&.id
    end

    def category_name
      category&.name
    end

    def parent_category_name
      parent_category&.name
    end

    # 除了自身的状态，还要判断item的状态
    # 为了优化接口，避免item重复查询，所以允许传item
    def is_on_sale?(arg_item = nil)
      on_sale? && (arg_item ? arg_item.on_sale? : item_on_sale?)
    end

    def show_on_sale_soon_tag
      on_sale? && item_show_on_sale_soon_tag
    end

    def price_less_than_supplier_cost_multiple?(new_price_in_cent = nil)
      cost = newest_supplier_cost_in_cent

      if cost.present? && cost.positive?
        tmp_price = new_price_in_cent.presence || price_in_cent
        site_config = store.site_config
        # 先判断是否小于倍數的金額，如果是，再判断 售价-进货价 是否小于最小利润金额
        if tmp_price < cost * site_config.sku_cost_minimum_factor
          if site_config.sku_minimum_profit_in_cent.present?
            (tmp_price - cost) < site_config.sku_minimum_profit_in_cent
          else
            true
          end
        else
          false
        end
      else
        false
      end
    end

    def new_user_price_less_than_supplier_cost_multiple?(new_price_in_cent = nil)
      cost = newest_supplier_cost_in_cent

      if cost.present? && cost.positive?
        tmp_price = new_price_in_cent.presence || new_user_price_in_cent

        return false if tmp_price.nil?

        site_config = store.site_config
        # 先判断是否小于倍數的金額，如果是，再判断 售价-进货价 是否小于最小利润金额
        if tmp_price < cost * site_config.sku_cost_minimum_factor
          if site_config.sku_minimum_profit_in_cent.present?
            (tmp_price - cost) < site_config.sku_minimum_profit_in_cent
          else
            true
          end
        else
          false
        end
      else
        false
      end
    end

    # 同时设置了新人价及新人限购数才需要对比数量
    def new_user_buy_quota_invalid?(qty, current_user)
      all_qty = qty + current_user.sku_bought_quantity(id)
      new_user_price_in_cent.to_i.positive? && new_user_buy_quota.to_i.positive? && all_qty > new_user_buy_quota
    end

    def generate_change_log(params)
      log_message = []
      if new_record?
        log_message << "导入新增SKU, 货号为：#{params["no"]}, 数量为：#{params["quantity"]}, 价格为：#{params["price_in_yuan"]}, 折扣价为：#{params["discount_price_in_yuan"] || "空"}, 购买数量大于等于为：#{params["discount_quantity"] || "空"}"
      else
        # 字符串属性
        %w[price_in_yuan quantity discount_price_in_yuan discount_quantity barcode].each do |attr|
          new_value = params[attr].to_s
          current_value = self.send(attr).to_s
          if new_value.present? && new_value != current_value
            log_message << "导入修改SKU（#{no}）#{self.class.human_attribute_name(attr)}: 从 #{current_value.presence || "空"} 改为 #{new_value.presence || "空"}"
          end
        end

        new_is_special = params["is_special"]
        if !new_is_special.nil? && new_is_special != is_special
          log_message << "导入修改SKU（#{no}）是否特品: 从 #{is_special ? "是" : "否"} 改为 #{new_is_special ? "是" : "否"}"
        end

        new_is_private_kitchen = params["is_private_kitchen"]
        if !new_is_private_kitchen.nil? && new_is_private_kitchen != is_private_kitchen
          log_message << "导入修改SKU（#{no}）是否私厨: 从 #{is_private_kitchen ? "是" : "否"} 改为 #{new_is_private_kitchen ? "是" : "否"}"
        end

        new_marketing_mode = params["marketing_mode"]
        if new_marketing_mode.present? && new_marketing_mode != marketing_mode
          log_message << "导入修改SKU（#{no}）营销模式: 从 #{I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{marketing_mode}")} 改为 #{I18n.t("activerecord.attributes.magic_bean/stock_keeping_unit/marketing_modes.#{new_marketing_mode}")}"
        end
      end

      log_message.join("，")
    end

    def in_time_limited_promotion?
      return false if new_record?

      in_time_limited_promotion.value == "true"
    end

    def generate_valid_inventory_dates
      sku_valid_inventory_dates.find_or_create_by(date: Date.current, store_id: store_id)
    end

    def try_set_first_sale_time
      return if first_sale_at.present?
      return unless on_sale?

      if item.online?
        self.first_sale_at = Time.current
      elsif item.advance_on?
        self.first_sale_at = item.start_selling_at
      end

      item.update(first_sale_at: first_sale_at) if item.first_sale_at.blank?
    end

    def shopline_synced?
      shopline_sku.present?
    end

    def aliexpress_synced?
      ae_sku.present?
    end

    def aliexpress_sync_stock
      return unless aliexpress_synced?

      response = Aliexpress::Sku.edit_mutilple_sku_stocks(
        product_id: item.ae_item.third_party_id,
        sku_stocks: [[ae_sku.third_party_id, quantity]].to_h
      )
      response.body
    end

    def self.aliexpress_sync_stock(sku, stock)
      return unless sku.aliexpress_synced?

      response = Aliexpress::Sku.edit_mutilple_sku_stocks(
        product_id: sku.item.ae_item&.third_party_id,
        sku_stocks: [[sku.ae_sku.third_party_id, stock]].to_h
      )
      response.body
    end

    def self.aliexpress_sync_price(sku, price)
      return unless sku.aliexpress_synced?

      response = Aliexpress::Sku.edit_single_sku_price(
        product_id: sku.item.ae_item.third_party_id,
        sku_id: sku.ae_sku.third_party_id,
        sku_price: (price * MagicBean::Item::DEFAULT_AE_EXCHANGE_RATE * MagicBean::Item::DEFAULT_AE_FACTOR).round(2).to_s
      )
      response.body
    end

    def self.reorder_by_ids(ids)
      order_by = ["CASE"]
      ids.each_with_index do |id, i|
        order_by << "WHEN stock_keeping_units.id='#{id}' THEN #{i}"
      end
      order_by << "END"
      reorder(Arel.sql(order_by.join(" ")))
    end

    private

    # 保存之前获取更多的商品信息
    def set_groups_properties
      return [] if groups.nil?
      groups.map! do |child|
        relation = child["type"].constantize.find_by(id: child["id"])
        child.merge!(
          cover: relation.cover,
          no: relation.no,
          item_id: child["type"].eql?("MagicBean::Item") ? relation.id : relation.item.id,
        )
        child.stringify_keys
      end
    end

    # 根据 pid 大小升序排列
    def order_sku_properties
      sorted_properties = properties_ids_array.sort_by do |p_v|
        pid = p_v.split(PID_VID_SEPARATOR).first
        pid.to_i
      end.join(PROPERTIES_SEPARATOR)

      self.properties = sorted_properties
    end

    def set_default_value
      self.store_id = item.store_id
      self.is_special = false if is_special.nil?
      self.is_private_kitchen = false if is_private_kitchen.nil?
      self.marketing_mode = "self_support" if marketing_mode.nil?
    end

    def properties_ids_exist
      # 需要确保 pids 和 vids 存在数据库对应的 text 值
      if MagicBean::SkuProperty.where(id: pids).size != pids.size || MagicBean::SkuValue.where(id: vids).size != vids.size
        errors.add :properties, :inclusion
      end
    end

    def properties_ids_unique
      # 需确保没有重复的 properties 和 values
      unless pids.size == pids.uniq.size && vids.size == vids.uniq.size
        errors.add :properties, :invalid
      end
    end

    def properties_matched
      # 需确保 vid 关联对应的 pid
      properties_ids_array.each do |p_v|
        pid, vid = p_v.split(PID_VID_SEPARATOR)
        if MagicBean::SkuValue.where(id: vid, sku_property_id: pid).empty?
          errors.add :properties, :invalid
        end
      end
    end

    def update_item_quantity
      return if item.destroyed?
      
      # 库存并发处理使用了save!方法，但值都没变化，所以这里要把previous_changes为空的场景也处理
      if quantity_previously_changed? || on_sale_previously_changed? || destroyed? || previous_changes.blank?
        item.reload
        # 如果item是上架状态，这里需要触发回调；如果是下架状态，不需要触发回调，避免导入情况信息不全导致更新失败
        if item.pending?
          item.update_columns(quantity: item.on_sale_skus.sum(:quantity))
        else
          item.update(quantity: item.on_sale_skus.sum(:quantity))
        end
      end

      return unless item.on_sale_base_listing_type?

      # 通知订阅到货通知的用户情况:
      # 库存由0改成非0, 且sku为上架状态
      # sku由下架改为上架，且数量大于0
      SendSkuInStockNoticeJob.perform_later(id) if
        ((quantity_previously_changed? && quantity_previous_change[0] == 0 && on_sale) ||
          (on_sale_previously_changed? && on_sale_previous_change[0] == false && quantity.positive?)) &&
          sku_in_stock_notices.pending.any?
    end

    def update_item_price_in_cent
      return if item.destroyed?
      if price_in_cent_previously_changed? || on_sale_previously_changed? || destroyed?
        item.reload
        calculate_and_update_item_price
      end
    end

    def calculate_and_update_item_price
      min_normal_price_in_cent = item.on_sale_skus.minimum(:price_in_cent).to_i

      min_promotion_price = MagicBean::TimeLimitedPromotionPrice.active.where(stock_keeping_unit_id: item.on_sale_skus.ids).minimum(:price_in_cent)

      if min_promotion_price.present?
        min_item_price = [min_normal_price_in_cent, min_promotion_price].min
        item.strikethrough_price_in_cent = min_normal_price_in_cent if min_item_price != min_normal_price_in_cent && item.strikethrough_price_in_cent.blank?
      else
        min_item_price = min_normal_price_in_cent
      end

      item.price_in_cent = min_item_price
      if item.strikethrough_price_in_cent == min_item_price
        item.strikethrough_price_in_cent = nil
      end

      item.save(validate: false)
    end

    def calculate_and_update_item_strikethrough_price
      new_strikethrough_price_in_cent = item.on_sale_skus.minimum(:strikethrough_price_in_cent)

      min_normal_price_in_cent = item.on_sale_skus.minimum(:price_in_cent).to_i
      min_promotion_price = MagicBean::TimeLimitedPromotionPrice.active.where(stock_keeping_unit_id: item.on_sale_skus.ids).minimum(:price_in_cent)

      if min_promotion_price.present?
        min_item_price = [min_normal_price_in_cent, min_promotion_price].min
        if min_item_price != min_normal_price_in_cent && new_strikethrough_price_in_cent.blank?
          new_strikethrough_price_in_cent = min_normal_price_in_cent
        end
      end

      if item.pending?
        item.update_columns(strikethrough_price_in_cent: new_strikethrough_price_in_cent)
      else
        item.update(strikethrough_price_in_cent: new_strikethrough_price_in_cent)
      end
    end

    def reset_strikethrough_price
      self.strikethrough_price_in_cent = nil if strikethrough_price_in_cent&.zero?
    end

    def update_item_strikethrough_price_in_cent
      return if item.destroyed?
      # 下面这种情况会导致item划线价不正确
      # 先把sku价格跟划线价设置成一样，此时item划线价会为空；再单独修改sku价格，原来的触发条件不会更新item划线价
      # 所以需要sku价格变动时也要更新划线价
      if price_in_cent_previously_changed? || strikethrough_price_in_cent_previously_changed? || on_sale_previously_changed? || destroyed?
        item.reload
        calculate_and_update_item_strikethrough_price
      end
    end

    def update_item_new_user_price_in_cent
      return if item.destroyed?
      if new_user_price_in_cent_previously_changed? || on_sale_previously_changed? || destroyed?
        item.reload
        item.update_columns(new_user_price_in_cent: item.on_sale_skus.minimum(:new_user_price_in_cent))
      end
    end

    def format_barcodes
      return if barcode.blank?
      self.barcode = barcode.split(",").map(&:strip).map { |b| b.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "") }.uniq.join(",")
    end

    def format_no
      self.no = no&.strip
    end

    def format_barcode
      self.barcode = barcode&.strip&.gsub(/，/, ",")&.gsub("（", "(")&.gsub("）", ")")&.gsub(/['‘’\n]/, "")
    end

    def check_discount_quantity_and_price
      if (discount_quantity.present? && discount_price_in_cent.blank?) || (discount_quantity.blank? && discount_price_in_cent.present?)
        item.errors.add(:base, "购买数量和折扣价必须同时填写或同时为空")
      end

      if discount_quantity.present? && discount_price_in_cent.present? && (!discount_quantity.positive? || !discount_price_in_cent.positive?)
        item.errors.add(:base, "购买数量和折扣价必须为正数")
      end
    end

    def at_least_one_sku_if_item_on_sale
      if on_sale_changed?(from: true, to: false) && !item.pending?
        on_sale_sku_length = 0
        # 直接修改某个sku上架状态, 进到这个方数据还没更新，但能进入这里该数据可以认为是下架，所以判断上架数量要排除掉本商品
        item.stock_keeping_units.each { |sku| on_sale_sku_length += 1 if sku.on_sale && sku.id != id }

        if on_sale_sku_length.zero?
          # 通过item更新stock_keeping_units_attributes，on_sale为true，直接更新sku，on_sale为false，则不更新
          if on_sale
            item.errors.add(:base, "至少需要一个 SKU 上架")
          else
            self.errors.add(:base, "售卖的产品至少需要一个 SKU 上架")
          end
        end
      end
    end

    def set_valid_inventory_dates
      # 1. 修改了库存，库存大于0，为了避免每次库存变动都要去查数据库，这里判断原库存须为0
      # 2. 修改了SKU上架状态，上架状态为上架
      # 3. 判断item can_set_sku_valid_inventory_dates?是否为true
      if ((saved_change_to_quantity? && saved_change_to_quantity[0].to_i.zero?) || saved_change_to_on_sale?) && on_sale? && quantity.positive? && item.can_set_sku_valid_inventory_dates?
        generate_valid_inventory_dates
      end
    end

    def set_shopline_and_ae_price_in_cent
      self.shopline_price_in_cent = price_in_cent unless shopline_price_in_cent&.positive?
      self.ae_price_in_cent = price_in_cent unless ae_price_in_cent&.positive?
    end

    def check_if_shopline_need_to_sync
      # 产品删除的场景在third_party_item model中已经有同步，这里无需再处理
      return if item.destroyed? || !item.shopline_syncable?

      new_record = previous_changes.key?("id")

      if destroyed?
        SyncItemToShoplineJob.perform_later(item_id)
      elsif new_record
        # 新增sku，且上架状态，需要同步
        SyncItemToShoplineJob.perform_later(item_id) if on_sale
      else
        # 修改barcode、price、no、image、weight_in_gram触发同步
        # 修改库存直接同步最新库存
        SyncItemToShoplineJob.perform_later(item_id) if (previous_changes.keys & ["barcode", "price_in_cent", "no", "image", "weight_in_gram", "on_sale"]).present?
        # 后续这里改为先记录到redis，每五分钟同步一次库存
        # 库存并发处理使用了save!方法，但值都没变化，所以这里要把previous_changes为空的场景也处理
        UpdateShoplineInventoryJob.perform_later(id) if previous_changes.key?("quantity") || previous_changes.blank?
      end
    end

    # 图片来自速卖通 CDN（ae_drop_shipper 委托自 item），跳过白名单校验（与 job 的跳过条件一致）
    # item 缺失时按非跨境购处理、照常校验自身图片，避免 delegate 对 nil 抛错
    def resource_url_validation_enabled?
      !item&.ae_drop_shipper
    end

    def enqueue_generate_aws_lambda_image_job
      GenerateAwsLambdaImageJob.perform_later(self.class.name, id) unless ae_drop_shipper
    end
  end
end
