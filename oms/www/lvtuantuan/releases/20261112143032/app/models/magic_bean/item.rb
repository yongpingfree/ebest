# frozen_string_literal: true
module MagicBean
  class Item < ApplicationRecord
    searchkick text_middle: [:translated_searchable_title, :translated_searchable_description], language: "chinese", callbacks: false

    include PriceConvertConcern
    include FileUploadConcern
    include QrcodeConcern
    include ItemImportConcern
    include Redis::Objects
    include AliExpressProductConcern
    include ResourceUrlValidationConcern

    # scope
    # 商品可出售条件:
    #   1. 库存数量大于零
    #   2. 上架类型为：
    #     2.1 立即上架售卖，或者
    #     2.2 自定义上架时间且开售时间早于当前时间

    default_scope { order(Arel.sql("case when items.quantity > 0 then false else true end ASC, items.position ASC, items.created_at DESC")) }

    # 软删除的产品会关联订单项等，还需要展示，所以不放到default_scope
    # 管理后台软删除会把listing_type设置为pending, 所以前端接口无需调用not_deleted，只需要OMS产品列表调用即可
    scope :not_deleted, -> { where(deleted_at: nil) }
    # on_sale需要包含即将上架商品
    scope :on_sale, -> { where(listing_type: ["online", "advance_on"]) }
    scope :on_sale_with_stock, -> { where(listing_type: ["online", "advance_on"]).where("items.quantity > 0") }
    scope :express, -> { where("delivery_type @> ARRAY['express']::varchar[]") }
    scope :merchant_delivery, -> { where("delivery_type @> ARRAY['merchant_delivery']::varchar[]") }
    scope :self_pick, -> { where("delivery_type @> ARRAY['self_pick']::varchar[]") }
    scope :not_merchant_delivery, -> { where("? = ANY(delivery_type) or ? = ANY(delivery_type) or ? = ANY(delivery_type)", "self_pick", "express", "virtual_delivery") }  # 包含邮寄或自提或虚拟
    scope :virtual_delivery, -> { where("delivery_type @> ARRAY['virtual_delivery']::varchar[]") }
    scope :app_channel, -> { where("channels @> ARRAY['app']::varchar[]") }
    scope :mini_program_channel, -> { where("channels @> ARRAY['mini_program']::varchar[]") }
    scope :web_channel, -> { where("channels @> ARRAY['web']::varchar[]") }
    scope :shopline_channel, -> { where("channels @> ARRAY['shopline']::varchar[]") }
    scope :aliexpress_channel, -> { where("channels @> ARRAY['aliexpress']::varchar[]") }
    scope :special_offer, -> { where("items.strikethrough_price_in_cent > items.price_in_cent") }
    scope :not_gift, -> { where(gift_only: false) }

    # constants
    DELIVERY_TYPE_ARRAY = ["express", "self_pick", "merchant_delivery", "virtual_delivery"]
    CHANNEL_ARRAY = ["mini_program", "app", "web"]
    THIRD_PART_CHANNEL_ARRAY = ["shopline", "aliexpress"] # 第三方平台
    UPDATE_SKU_COLUMNS = %w(title sub_title category_id brand_id)
    NOT_DELIVERY_DAYS = ["2025-12-25", "2025-12-26", "2025-12-27", "2026-01-01"]
    MAX_POSITION = 99999999
    RESOURCE_URL_COLUMNS = [:main_images, :detail_images, :cover, :share_cover]
    ES_MIN_SCORE = 50
    ES_SEARCH_FIELDS = [
      "translated_searchable_title^12",
      "tags_name^7",
      "translated_searchable_description^3",
      "minor_category_name^1",
      "brand_name^1",
    ]

    AE_UNSALEABLE_CODE = [604, 605, 482]
    AE_CHOICE_DELIVERY_CODE = "CAINIAO_FULFILLMENT_STD"
    AE_CHOICE_DELIVERY_TIME = "10:00-23:00"

    # attr related macros
    alias_attribute :name, :title

    acts_as_taggable
    acts_as_taggable_on :comment_tags

    enum listing_type: {
      online: 1,
      advance_on: 2,
      pending: 3
    }

    enum item_type: {
      normal: 1,
      auction: 2,
      same_day_delivery: 3
    }

    enum freight_type: {
      freight_fixed: 1,
      freight_template: 2
    }

    enum storage_method: {
      room_temp_storage: 0,    # 常温
      refrigerated_storage: 1, # 冷藏
      frozen_storage: 2,       # 冷冻
      other_storage: 3,        # 其他
      blank_storage: 4         # /（不需要文字说明）
    }

    convert_price_to_yuan :price_in_cent, :strikethrough_price_in_cent, :fixed_freight, :fixed_freight_cost, :new_user_price_in_cent, :maximun_strikethrough_price_in_cent

    translates :title, :description, :shared_description
    globalize_accessors attributes: [:title, :description, :shared_description]

    # association macros
    belongs_to :category, optional: true, inverse_of: :items
    belongs_to :parent_category, optional: true, class_name: "MagicBean::Category", foreign_key: "parent_category_id"
    belongs_to :minor_category, optional: true, class_name: "MagicBean::Category", foreign_key: "minor_category_id"
    belongs_to :web_category, optional: true, inverse_of: :items
    belongs_to :parent_web_category, optional: true, class_name: "MagicBean::WebCategory", foreign_key: "parent_web_category_id"
    belongs_to :minor_web_category, optional: true, class_name: "MagicBean::WebCategory", foreign_key: "minor_web_category_id"
    belongs_to :qa_and_guarantee, optional: true
    belongs_to :brand, optional: true
    belongs_to :product, counter_cache: true
    belongs_to :store
    has_many :stock_keeping_units, -> { order(id: :asc) }, dependent: :destroy, inverse_of: :item
    has_many :on_sale_skus, -> { on_sale.order(id: :asc) }, class_name: "MagicBean::StockKeepingUnit"
    has_many :comments, dependent: :destroy
    has_many :groupon_activities, dependent: :destroy
    has_many :sku_groupons
    has_one :web_item
    has_many :operation_records, dependent: :destroy, as: :operatable
    has_many :histories, as: :operatable, class_name: "MagicBean::History", dependent: :destroy
    has_many :user_histories, as: :operatable, class_name: "MagicBean::UserHistory", dependent: :destroy
    has_many :custom_list_items, dependent: :destroy, inverse_of: :item
    has_many :custom_lists, through: :custom_list_items
    has_many :groupon_activities
    has_one :active_groupon_activity, -> { published.going }, class_name: "MagicBean::GrouponActivity", foreign_key: :item_id
    has_many :cutoff_times, dependent: :destroy
    has_many :order_items
    has_many :item_nutrition_values, dependent: :destroy
    has_many :nutritions, through: :item_nutrition_values
    has_many :web_custom_list_items, dependent: :destroy, inverse_of: :web_custom_list
    has_many :web_custom_lists, through: :web_custom_list_items
    has_many :item_tag_relations, dependent: :destroy
    has_many :item_tags, through: :item_tag_relations

    has_one :shopline_item, -> { shopline }, class_name: "MagicBean::ThirdPartyItem", dependent: :destroy
    has_one :ae_item, -> { aliexpress }, class_name: "MagicBean::ThirdPartyItem", dependent: :destroy

    has_and_belongs_to_many :default_freight_templates, association_foreign_key: "freight_template_id"

    belongs_to :ae_category, optional: true, class_name: "MagicBean::AeCategory", foreign_key: "ae_category_id", primary_key: "ae_id"

    # hot_sell_config_id仅为了传给前端方便跳转热卖榜
    belongs_to :hot_sell_config, optional: true

    accepts_nested_attributes_for :stock_keeping_units, :web_item, :product, :cutoff_times, allow_destroy: true
    attr_accessor :import_skip_validation

    # validation macros
    validates_uniqueness_of :no
    validates :leader, presence: true, if: -> { !import_skip_validation }
    validates :title_zh_cn, presence: true, if: -> { !import_skip_validation }
    validates :description_zh_cn, presence: true, if: -> { !import_skip_validation }
    validates :no, :main_images, :detail_images, :cover, presence: true
    validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :start_selling_at, presence: true, if: :advance_on?
    validates :likes_count_offset, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :fixed_freight, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { freight_fixed? }
    validates :stock_keeping_units, presence: true, if: -> { !import_skip_validation }
    validate :check_sales_count, on: :update
    validates :delivery_type, presence: true
    validate :validate_freight_templates, if: :freight_template?
    validate :check_category_id
    validate :check_channels
    validates :buy_quota_days, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { buy_quota&.positive? }
    validates :brand, :category, :qa_and_guarantee, :description, presence: true, if: -> { !import_skip_validation }
    # 导入的时候sku的barcode可以为空，只更新item的时候需要触发sku校验
    validates_associated :stock_keeping_units, message: "请检查sku必填字段、唯一性字段、售价是否大于进货价等信息", on: :update
    validates :presell_dispatch_on, :latest_presell_dispatch_on, :presell_end_at, presence: { if: :is_presell? }
    validate :presell_dispatch_on_valid?, if: :is_presell?
    validate :at_least_one_sku_if_change_to_sale
    validate :check_same_day_delivery_valid, if: :same_day_delivery?
    validates :days_ahead_to_show_expiration, numericality: { greater_than: 0 }, allow_nil: true
    validates :expiration_reminder_before_n_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    # validates :web_category_id, presence: true, if: ->(item) { item.channels.include?("web") } # TODO: 正式环境补充数据后加上这个校验

    # callbacks
    before_validation :set_no, :set_delivery_type, :format_title_and_description
    before_create :set_price_in_cent, :set_i18n_attributes
    after_commit :enqueue_generate_qrcode_job, on: :create, if: :normal?
    after_commit :enqueue_sku_in_stock_notice_job, on: :update
    after_commit :enqueue_sync_wms_product_job, on: :update, if: :short_title_previously_changed?
    after_commit :clear_same_day_delivery_cart_items, on: :update, if: :item_type_previously_changed?
    after_commit :clear_gift_only_cart_items, on: :update, if: :gift_only_previously_changed?
    after_commit :set_sku_valid_inventory_dates, on: :update, if: -> { listing_type_previously_changed? || start_selling_at_previously_changed? }
    after_save :try_set_skus_first_sale_time, if: -> { saved_change_to_listing_type? }
    after_save :update_skus_updated_at, if: :should_update_skus_updated_at?
    after_destroy :destroy_product
    before_save :set_parent_category, :translate_fields_with_zh_tw, :set_translated_searchable_attrs
    before_save :set_display_sales_count, if: Proc.new { sales_count_changed? || sales_count_offset_changed? }
    before_save :sort_and_set_delivery_weekdays, if: Proc.new { delivery_weekdays_changed? }
    before_save :reset_presell_date_time, unless: :is_presell?
    # first_sale_at是在after_save后触发保存，而last_sale_at和last_offline_at是在before_save需要判断first_sale_at是否有值再做下一步处理，所以在before_save中处理
    before_save :enqueue_sync_sku_attrs_job, :set_last_sale_at_and_last_offline_at, if: :will_save_change_to_listing_type?
    after_commit :enqueue_presell_item_pending_job, if: -> { is_presell? && saved_change_to_presell_end_at? }
    # after_commit :custom_reindex
    after_commit :enqueue_create_shopline_item_job, on: :create
    after_commit :enqueue_update_shopline_item_job, on: [:update, :destroy]
    # expiration_date变更时，触发定时任务
    after_commit :enqueue_update_product_metafields_job, if: -> { saved_change_to_expiration_date? }
    after_commit :enqueue_generate_aws_lambda_image_job, if: -> { main_images_previously_changed? || detail_images_previously_changed? || cover_previously_changed? || share_cover_previously_changed? }

    # other macros
    value :in_time_limited_promotion
    delegate :need_age_verification, to: :parent_category, prefix: true, allow_nil: true
    delegate :need_age_verification, to: :parent_web_category, prefix: true, allow_nil: true
    delegate :name, :cover, to: :brand, prefix: true, allow_nil: true
    delegate :name, to: :category, prefix: true, allow_nil: true
    delegate :name, to: :parent_category, prefix: true, allow_nil: true
    delegate :name, to: :minor_category, prefix: true, allow_nil: true
    delegate :name, to: :web_category, prefix: true, allow_nil: true
    delegate :name, to: :parent_web_category, prefix: true, allow_nil: true
    delegate :name, to: :minor_web_category, prefix: true, allow_nil: true
    delegate :image, :web_image, to: :qa_and_guarantee, prefix: true, allow_nil: true
    delegate :name, to: :store, prefix: true
    delegate :peti_store?, to: :store, prefix: false    
    delegate :name, to: :ae_category, prefix: true, allow_nil: true

    ransacker :item_type, formatter: proc { |v| item_types[v] }
    ransacker :listing_type, formatter: proc { |v| listing_types[v] }
    ransacker :freight_type, formatter: proc { |v| freight_types[v] }
    ransacker :storage_method, formatter: proc { |val| storage_methods[val] }

    # class methods
    class << self
      # 此方法为匹配数组中的任一个即可
      def delivery_type_contains_any(types = [])
        # 拼成 'self_pick', 'merchant_delivery'
        types = types.map { |type| "\'#{type}\'" }.join(",")
        where(Arel.sql("delivery_type && ARRAY[#{types}]::varchar[]"))
      end

      # 此方法为匹配数组中全部元素
      def delivery_type_contains(types = [])
        # 拼成 'self_pick', 'merchant_delivery'
        types = types.map { |type| "\'#{type}\'" }.join(",")
        where(Arel.sql("delivery_type @> ARRAY[#{types}]::varchar[]"))
      end

      # 此方法为匹配数组中的任一个即可
      def channels_contains_any(item_channels = [])
        # 拼成 'self_pick', 'merchant_delivery'
        channels_str = item_channels.map { |channel| "\'#{channel}\'" }.join(",")
        where(Arel.sql("channels && ARRAY[#{channels_str}]::varchar[]"))
      end

      # 此方法为匹配数组中全部元素
      def channels_contains(item_channels = [])
        channels_str = item_channels.map { |channel| "\'#{channel}\'" }.join(",")
        where(Arel.sql("channels @> ARRAY[#{channels_str}]::varchar[]"))
      end

      # 用于分类自定义排序产品
      def reorder_by_ids(ids)
        order_by = ["CASE"]
        ids.each_with_index do |id, i|
          order_by << "WHEN items.id='#{id}' THEN #{i}"
        end
        order_by << "END"
        reorder(Arel.sql(order_by.join(" ")))
      end

      # 猜你喜欢只支持非跨境购商品
      def guess_you_like_item_ids(arg_user, arg_store_id, arg_channel)
        # 用户不存在或用户超过14天没访问过app，直接返回随机数组
        if arg_user.blank? || arg_user.last_visit_at.blank? || arg_user.last_visit_at < 14.days.ago
          return guess_you_like_random_item_ids(arg_store_id, arg_channel)
        end

        # 确保每天的随机数因子一样
        srand Date.current.day
        item_ids = []

        tmp_collection = on_sale_with_stock.not_gift.where(store_id: arg_store_id, ae_drop_shipper: false).send("#{arg_channel}_channel")

        # 获取浏览记录前三的二级分类，第一名15个商品、第二名9个、第三名6个
        history_hash = arg_user.user_histories.where(operatable_type: "MagicBean::Item").where("view_date >= ?", Date.current - 14.days).group(:operatable_id).sum(:count)

        if history_hash.present?
          sort_item_ids = history_hash.sort_by { |_key, value| value }.reverse.to_h.keys
          target_category_ids = where(id: sort_item_ids, ae_drop_shipper: false).reorder_by_ids(sort_item_ids).map(&:category_id).uniq.first(3)

          target_category_ids.each_with_index do |cate_id, index|
            count = if index.zero?
                      15
                    elsif index == 1
                      9
                    else
                      6
                    end
            item_ids += tmp_collection.where(category_id: cate_id).reorder("random()").limit(count).ids
          end
        end

        # 用户最近搜索关键字根据channel再随机10个商品
        recent_item_search_words = arg_user.send("#{arg_channel}_recent_item_search_words")
        if recent_item_search_words.present?
          item_ids += tmp_collection.where.not(id: item_ids).ransack({ translated_searchable_title_or_sub_title_or_translated_searchable_description_cont_any: recent_item_search_words }).result.reorder("random()").limit(10).ids
        end

        # 如果上面两个规则40个商品还没满，则随机补满40个
        item_ids += tmp_collection.where.not(id: item_ids).reorder("random()").limit(40 - item_ids.uniq.length).ids
        item_ids.uniq
      end

      def guess_you_like_random_item_ids(arg_store_id, arg_channel)
        key = "@random_item_ids_#{arg_store_id}_#{arg_channel}"
        random_item_ids = instance_variable_get(key)
        return random_item_ids if random_item_ids.present?

        # 确保每天的随机数因子一样
        srand Date.current.day
        instance_variable_set(key, on_sale_with_stock.not_gift.where(store_id: arg_store_id, ae_drop_shipper: false).send("#{arg_channel}_channel").reorder("random()").limit(40).ids)
      end

      # 创建AE商品
      def create_ae_item(product_id)
        return true if self.exists?(no: product_id)
        retry_times = 3
        @sydney_store ||= MagicBean::Store.sydney
        @freight_template ||= MagicBean::FreightTemplate.where(store_id: @sydney_store.id).express.ransack(translations_name_cont:"跨境购").result.first
        @brand ||= MagicBean::Brand.find_or_create_by(name: "跨境购")
        @qa_and_guarantee ||= MagicBean::QaAndGuarantee.find_by(title: "跨境购")

        # 进货价最小倍数
        ae_sku_cost_minimum_factor = @sydney_store.site_config&.ae_sku_cost_minimum_factor

        begin
          detail_response = Aliexpress::Api.get_dropshipper_product_detail(product_id)
          # 当商品不再销售时，返回数据为 {"rsp_code"=>604, "rsp_msg"=>"All SKU  ", "request_id"=>"21015f2417277036411565558"}，这个场景返回true
          # {"rsp_code"=>482, "rsp_msg"=>"SHIP_TO_COUNTRY_PROHIBITED"}
          # 1005007587784249: {"rsp_code"=>605, "rsp_msg"=>"ITEM_ID_NOT_FOUND", "request_id"=>"21410fef17283947627768106"}
          return false if detail_response.body.dig("rsp_code").in?(AE_UNSALEABLE_CODE)

          product_result = detail_response.body.dig("result")
          
          item_images = product_result["ae_multimedia_info_dto"]["image_urls"].split(";")
          item_info = product_result["ae_item_base_info_dto"]
          skus_info = product_result["ae_item_sku_info_dtos"]
          package_info = product_result["package_info_dto"]
          parent_category_name, category_name = item_info["category_sequence"].split("/").first(2).map {|name| name.strip}
          category_id = item_info["category_id"]
          item_properties = product_result["ae_item_properties"]
          is_ae_choice = item_properties.any? {|property| property["attr_name_id"] == -1 && property["attr_name"] == "Choice" && property["attr_value"] == "yes" }

          # 非AE Choice的产品不创建
          return false unless is_ae_choice

          # 不可售商品直接不创建
          return false if item_info["product_status_type"] != "onSelling"
    
          parent_category = MagicBean::Category.top.where(ae_drop_shipper: true).ransack(translations_name_cont: parent_category_name).result.first
          # AE的二级分类出现了很多相同名字但id不同的情况，所以需要用category_name来查询
          category = parent_category.children.ransack(translations_name_cont: category_name).result.first
          # 如果category不存在，则创建二级分类
          if category.blank?
            category_name_zh_cn = EasyTranslate.translate(category_name, from: :en, to: :"zh-CN")
            category = MagicBean::Category.create(
              name_zh_cn: category_name_zh_cn,
              name_en: category_name,
              ae_drop_shipper: true,
              parent_id: parent_category.id,
              ae_drop_shipper_category_id: category_id
            )
          end
    
          stock_keeping_units_attributes = []
          skus_info.each do |sku|
            # product_id: 1005006204446005返回了异常数据：[{"sku_attr"=>"","offer_sale_price"=>"4.90","ipm_sku_stock"=>23,"sku_stock"=>true,"sku_id"=>"12000036261008824","price_include_tax"=>false,"currency_code"=>"AUD","sku_price"=>"4.90","offer_bulk_sale_price"=>"4.90","sku_available_stock"=>23,"id"=>""}]
            next if sku["id"].blank?
            sku_properties = sku["ae_sku_property_dtos"]
    
            properties = sku_properties.map do |property|
              sku_property_str = property["sku_property_name"]&.strip
              sku_value_str = property["sku_property_value"]&.strip
              sku_definition_name = property["property_value_definition_name"]&.strip
    
              sku_value_str = "#{sku_value_str}(#{sku_definition_name})" if sku_definition_name.present? && sku_value_str != sku_definition_name
    
              # 将规格名跟普通商品区分开，加上ae_property_id
              sku_property = MagicBean::SkuProperty.find_or_create_by(text: sku_property_str, ae_property_id: property["sku_property_id"])
              # 1005005453331843返回的数据出现了规格值完全一样，但id不一样的情况，所以需要把property_value_id也带上
              sku_value = sku_property.sku_values.find_or_create_by(text: sku_value_str, ae_property_value_id: property["property_value_id"])
              "#{sku_property.id}:#{sku_value.id}"
            end.join(";")

            # offer_sale_price: 折扣后的价格
            # sku_price: 原价
            ae_price = sku["offer_sale_price"].presence || sku["sku_price"]
            if ae_sku_cost_minimum_factor.present?
              # 售价和划线价乘最小倍数
              sale_price = (ae_price.to_f * ae_sku_cost_minimum_factor).round(2)
              strikethrough_price = (sku["sku_price"].to_f * ae_sku_cost_minimum_factor).round(2)
            else
              sale_price = ae_price
              strikethrough_price = sku["sku_price"]
            end

            # 如果划线价小于等于售价，则划线价为空
            strikethrough_price = nil if strikethrough_price <= sale_price
    
            stock_keeping_units_attributes << {
              no: sku["sku_id"], # 用ae sku_id
              ae_sku_attr: sku["sku_attr"], # 下单需要用到该字段
              properties: properties,
              price_in_yuan: sale_price,
              strikethrough_price_in_yuan: strikethrough_price,
              ae_price_in_yuan: ae_price,
              quantity: sku["sku_available_stock"],
              gst_percent: 0,
              marketing_mode: "consign_for_sale",
              image: sku_properties.first["sku_image"],
              barcode: sku["sku_id"], # 用sku_id
              weight_in_gram: (package_info["gross_weight"].to_f * 1000).round, # 返回的单位是kg
              length_in_cm: package_info["package_length"],
              width_in_cm: package_info["package_width"],
              height_in_cm: package_info["package_height"],
              on_sale: true,
              is_special: false,
            }
          end
    
          return false if stock_keeping_units_attributes.blank?
    
          title_en = item_info["subject"]
          title_zh_cn = EasyTranslate.translate(title_en, from: :en, to: :"zh-CN")
          title_zh_tw = Ropencc.conv("s2tw.json", title_zh_cn)
    
          item_attributes = {
            leader: "其他",
            title_zh_cn: title_zh_cn,
            title_zh_tw: title_zh_tw,
            title_en: title_en,
            description_zh_cn: title_zh_cn, # 描述先默认title
            description_zh_tw: title_zh_tw,
            description_en: title_en,
            ae_h5_description: item_info["detail"],
            cover: item_images.first, # 拿媒体文件的第一个
            category_id: category.id,
            brand_id: @brand.id,
            qa_and_guarantee_id: @qa_and_guarantee.id, # 先拿第一个，后面再新建一个
            store_id: @sydney_store.id,
            sales_count: item_info["sales_count"],
            channels: ["app"],
            coupon_enabled: false,
            item_type: "normal",
            listing_type: "pending", # 如果是更新，需要比对item_info["product_status_type"]
            no: product_id, # 用product_id
            ae_drop_shipper: true,
            freight_type: "freight_template",
            delivery_type: ["express"],
            default_freight_template_ids: [@freight_template.id],
            storage_method: :room_temp_storage,
            main_images: [item_images.first],
            detail_images: item_images,
            is_ae_choice: is_ae_choice,
            ae_unsaleable: false,
            stock_keeping_units_attributes: stock_keeping_units_attributes,
            ae_basic_info_last_updated_date: Date.current,
          }
    
          item_attributes[:product_attributes] = {
            title: item_attributes[:title_en],
            description: item_attributes[:description_en],
            cover: item_attributes[:cover],
            category_id: item_attributes[:category_id],
            qa_and_guarantee_id: item_attributes[:qa_and_guarantee_id],
            brand_id: item_attributes[:brand_id],
            store_id: item_attributes[:store_id],
            detail_images: item_attributes[:detail_images],
            main_images: item_attributes[:main_images],
          }
    
          item = self.new(item_attributes)
          item.save
        rescue => _
          # 请求可能会超过频率导致失败，需要重试
          retry_times -= 1
          retry_times > 0 ? retry : false
        end
      end

      # first_sale_at在30天内，或last_sale_at在30天内，且last_offline_at大于等于180天
      def new_product_ransack_params
        [
          { m: 'or',
            g: [{ first_sale_at_gteq: 1.month.ago.beginning_of_day }, { m: 'and', g: [{ last_sale_at_gteq: 1.month.ago.beginning_of_day }, { last_offline_at_lteq: 180.days.ago.beginning_of_day }] }]
          }
        ]
      end
    end

    # `sku_options` 返回以下格式的 sku 选项对照表：
    # {
    #   {:pid=>2, :text=>"型号"}: [{:vid=>5, :text=>"iPhone Xs"}, {:vid=>6, :text=>"iPhone XR"}, {:vid=>7, :text=>"iPhone X"}, {:vid=>8, :text=>"iPhone 8 Plus"}]],
    #   {:pid=>3, :text=>"机身颜色"}: [{:vid=>9, :text=>"银色"}, {:vid=>10, :text=>"深空灰色"}, {:vid=>11, :text=>"金色"}, {:vid=>12, :text=>"红色"}],
    #   {:pid=>4, :text=>"内存"}: [{:vid=>13, :text=>"64G"}, {:vid=>14, :text=>"128G"}, {:vid=>15, :text=>"256G"}, {:vid=>16, :text=>"512G"}]
    # }
    def sku_options
      return @sku_options if @sku_options

      @sku_options = []
      return @sku_options if stock_keeping_units.empty?

      # TODO: 标记没有库存的 sku
      # 思路：返回 sku properties:inventory lookup table
      vids = stock_keeping_units.map(&:vids).reduce([], :+)
      MagicBean::SkuProperty.where(id: stock_keeping_units.first.pids).includes(:translations).each do |property|
        property_key = { id: property.id, text: property.text, sku_values: [] }
        property.sku_values.where(id: vids).includes(:translations).each do |val|
          property_key[:sku_values] << { id: val.id, text: val.text, sku_property_id: val.sku_property_id }
        end
        @sku_options << property_key
      end

      @sku_options
    end

    def on_sale_sku_options
      return @on_sale_sku_options if @on_sale_sku_options

      @on_sale_sku_options = []
      return @on_sale_sku_options if on_sale_skus.empty?

      # TODO: 标记没有库存的 sku
      # 思路：返回 sku properties:inventory lookup table
      vids = on_sale_skus.map(&:vids).reduce([], :+)
      MagicBean::SkuProperty.where(id: on_sale_skus.first.pids).includes(:translations).each do |property|
        property_key = { id: property.id, text: property.text, sku_values: [] }
        property.sku_values.where(id: vids).includes(:translations).each do |val|
          # 如果text包含了英文括号，则取第一个括号里面的值，例如 XXL(2XL Fit(81-88kg)) -> 2XL Fit(81-88kg)
          val_text = val.text
          if val_text.match(/\(.*\)/)
            val_text = val_text[/\((.*)\)/, 1]
          end
          property_key[:sku_values] << { id: val.id, text: val_text, sku_property_id: val.sku_property_id }
        end
        @on_sale_sku_options << property_key
      end

      @on_sale_sku_options
    end

    def total_likes_count
      @total_likes_count ||= likes_count_offset + likes_count
    end

    # 暂时弃用
    def monthly_sales_count
      @monthly_sales_count ||=
        unless monthly_sales_count_offset.to_i.zero?
          actual_monthly_sales_count * 5 + monthly_sales_count_offset
        else
          actual_monthly_sales_count
        end
    end

    # 总销量显示
    def calculate_display_sales_count
      if sales_count_offset.to_i.zero?
        sales_count
      else
        sales_count * 5 + sales_count_offset
      end
    end

    def calculate_freight(weight_in_gram, postal_code, city_name, tmp_delivery_type)
      # 若配送方式与产品配送方式不匹配，订单会报错
      return [0, 0] unless tmp_delivery_type.in? self.delivery_type

      if freight_fixed?
        [fixed_freight, fixed_freight_cost]
      elsif freight_template?
        default_freight_templates.where(store_id: store_id).public_send(tmp_delivery_type).first&.calculate_freight(weight_in_gram, postal_code, city_name).presence || [0, 0]
      else
        [0, 0]
      end
    end

    def calculate_actual_monthly_sales_count
      self.actual_monthly_sales_count = MagicBean::OrderItem.sold_in_last_30_days.where(item: self).sum(:quantity)
    end

    def price_range
      min_price == max_price ? min_price : "#{min_price}-#{max_price}"
    end

    def min_price
      @min_price ||= (on_sale? ? on_sale_skus.min { |a, b| a.final_price(nil).first <=> b.final_price(nil).first }&.final_price(nil).second : price_in_yuan)
    end

    def max_price
      @max_price ||= (on_sale? ? on_sale_skus.max { |a, b| a.final_price(nil).first <=> b.final_price(nil).first }&.final_price(nil).second : price_in_yuan)
    end

    def on_sale_base_listing_type?
      online? || (advance_on? && start_selling_at < Time.current)
    end

    def channel_match?(current_channel)
      self.channels.include?(current_channel)
    end

    def channels_text
      channels.map do |channel|
        I18n.t("grape.channels.#{channel}")
      end.join("/")
    end

    def on_sale?
      in_stock? && on_sale_base_listing_type? && on_sale_skus.any?
    end

    def first_comment
      display_comments.first
    end

    # 产品详情页的评论数只显示3条
    def item_display_comments
      display_comments.limit(3)
    end

    def display_comments
      comments.top_level.show.order(is_top: :desc, created_at: :desc)
    end

    def mini_program_path
      "pages/products/detail/detail?id=#{id}"
    end

    def app_path
      { type: "productDetail", params: { id: id } }.to_json
    end

    def can_show_normal_orders
      MagicBean::OrderItem.normal_order.exists?(stock_keeping_unit_id: stock_keeping_units.ids)
    end

    def can_show_groupon_orders
      MagicBean::OrderItem.groupon.exists?(stock_keeping_unit_id: stock_keeping_units.ids)
    end

    def can_show_virtual_orders
      MagicBean::OrderItem.virtual_order.exists?(stock_keeping_unit_id: stock_keeping_units.ids)
    end

    def destroyable?
      stock_keeping_units.includes(:order_items).map(&:order_items).flatten.empty? && (product.items_count < 2 || product.store_id != self.store_id)
    end

    def pending_comments_count
      comments.pending.count
    end

    def calculate_delivery_area(postal_code, suburb)
      MagicBean::DeliveryArea.ransack(
        postal_code_eq: postal_code&.strip || -1,
        suburb_case_insensitive_eq: suburb&.strip&.downcase || -1
      ).result.first
    end

    def calculate_earliest_dispatch_time(time, site_config = nil)
      # 如果是跨境购商品，则由ae_delivery_date字段来决定发货时间（库存为0时，AE不会返回配送日期，所以存在配送日期为空的情况）
      if ae_drop_shipper?
        return {} if ae_delivery_date.blank?
        available_date = ae_delivery_date.to_date
        @earliest_dispatch_time = {
          use_merchant_delivery: false,
          selected_cot: nil,
          date: available_date,
          wday: I18n.l(available_date, format: "%a"),
          time: AE_CHOICE_DELIVERY_TIME,
          latest_presell_dispatch_date: nil
        }
        return @earliest_dispatch_time
      end

      limit = 0

      original_time = time
      @earliest_dispatch_time ||= nil
      cot = nil
      latest_presell_dispatch_date = nil

      return @earliest_dispatch_time if @earliest_dispatch_time

      # 预售商品要从预售发货时间开始算起
      if is_presell? && presell_dispatch_on?
        presell_dispatch_at = presell_dispatch_on.beginning_of_day
        latest_presell_dispatch_date = latest_presell_dispatch_on
        time = presell_dispatch_at if time < presell_dispatch_at
      end

      if target_cutoff_time.present?
        loop do
          wday = time.wday.to_s

          if wday.in?(target_cutoff_time.weekdays)
            # 当天需要过滤掉时间比传入时间小的数据
            selected_times = target_cutoff_time.time_at.sort

            # 预售商品都是未来时间的商品，取第一个时间
            if limit.zero? && !is_presell?
              # 找到比当前时间大的最小时间
              cot = selected_times.find { |t| t > time.strftime("%H:%M") }
              # 如果找不到比当前时间大的最小时间，说明当前时间已经过了商品截止时间，则需要加1天
              if cot.blank?
                cot = selected_times.first
                time += 1.day
              end
            else
              cot = selected_times.first
            end
           
            break
          end

          time += 1.day
          limit += 1
          # 一周内肯定有一天符合需求，所以不需要改为30
          break if limit > 7
        end
      else
        # 当item没有COT时，则将传进来的时间跟store COT进行比较
        cot = time.strftime("%H:%M")
      end

      # 先找出大于或等于item计算出来的COT的store COT
      store_site_config = site_config || current_store_site_config
      selected_cot = store_site_config.format_cutoff_time.reject { |t| t[:time] < cot }.first

      # 预售商品需要另外计算
      if is_presell? && time > Time.current
        selected_cot = store_site_config.format_cutoff_time.first if selected_cot.blank?
        if original_time > selected_cot[:time].in_time_zone && time.to_date == Date.current.tomorrow
          time += 1.day
        end
        available_date = "#{time.strftime("%Y-%m-%d")} #{selected_cot[:time]}".in_time_zone.to_date
      else
        # 若找不到比item COT大的store COT，则拿第二天的第一个store COT
        if selected_cot.blank?
          selected_cot = store_site_config.format_cutoff_time.first
          time += 1.day
        end

        # 全站配置截单时间是隔天发货，如果设置了商品截止时间，则不管全站配置的隔天发货，以商品截止时间的 截单后N天发货为准
        if target_cutoff_time.present?
          available_date = ("#{time.strftime("%Y-%m-%d")} #{selected_cot[:time]}".in_time_zone + (target_cutoff_time.deliver_after_n_days).days).to_date
        else
          available_date = ("#{time.strftime("%Y-%m-%d")} #{selected_cot[:time]}".in_time_zone + (selected_cot[:time_kind] == "next_day" ? 1 : 0).days).to_date
        end
      end

      @earliest_dispatch_time = {
        use_merchant_delivery: false,
        selected_cot: selected_cot,
        date: available_date,
        wday: I18n.l(available_date, format: "%a"),
        time: selected_cot[:earliest_delivery_time],
        latest_presell_dispatch_date: latest_presell_dispatch_date
      }
    end

    def calculate_earliest_delivery_time(time, postal_code = nil, suburb = nil, self_pick_up_id = nil)
      earliest_delivery_time = calculate_earliest_dispatch_time(time).dup
      # 非自提和自派商品直接返回earliest_delivery_time
      return earliest_delivery_time if (delivery_type & ["merchant_delivery", "self_pick"]).blank?

      earliest_delivery_date = earliest_delivery_time[:date]

      current_delivery_area = calculate_delivery_area(postal_code, suburb)
      self_pick_up = self_pick_up_id.present? ? MagicBean::SelfPickUp.find_by(id: self_pick_up_id) : nil

      # 判断用户是否在配送区域内，若是，则使用delivery_time, 若不是，则用dispatch_time
      @available_delivery_time ||= self_pick_up || current_delivery_area&.delivery_time

      if @available_delivery_time
        tmp_not_delivery_dates = NOT_DELIVERY_DAYS

        if self_pick_up.present?
          self_pick_orders_limit = self_pick_up.self_pick_orders_limit_every_day.to_i.abs
        else
          has_no_limit_setting = @available_delivery_time.delivery_time_period_settings.where(order_address_limit_every_day: 0).exists?
          total_address_limit = @available_delivery_time.delivery_time_period_settings.sum(:order_address_limit_every_day)
        end

        # 特殊需求: 关闭卧龙岗几个配送时间管理9月16日-9月24日的配送日期
        # if (self_pick_up.present? && @available_delivery_time.id.in?([11])) || (self_pick_up.blank? && @available_delivery_time.id.in?([11, 22, 23]))
        #   tmp_not_delivery_dates = (tmp_not_delivery_dates + ("2022-09-16".."2022-09-24").to_a).uniq
        # end

        limit = 1
        loop do
          # 布里斯班2023-07-01之后的日期不可选
          # 2024-01-26是澳洲国庆，2000邮编的自派订单均不配送
          unless earliest_delivery_date.to_s.in?(tmp_not_delivery_dates) || (store_id == 4 && earliest_delivery_date.to_s >= "2023-07-01") || (store_id == 3 && earliest_delivery_date.to_s >= "2023-08-20") || (self_pick_up.blank? && earliest_delivery_date.to_s == "2024-01-26" && postal_code.to_s == "2000")
            available_weekdays = delivery_weekdays.present? ? (@available_delivery_time.weekdays & delivery_weekdays) : @available_delivery_time.weekdays

            if earliest_delivery_date.wday.to_s.in?(available_weekdays)
             
              # 全站配置的地址数上限
              custom_merchant_address_limit = merchant_delivery_address_limit

              # 如果limited_by_orders_limit_every_day为true, 且全站配置地址数都为0，则不限制
              # 如果limited_by_orders_limit_every_day为false, 且delivery_time_period_settings存在不限制地址数的设置，则不限制
              break if current_delivery_area.present? && ((@available_delivery_time.limited_by_orders_limit_every_day && custom_merchant_address_limit.zero?) || (!@available_delivery_time.limited_by_orders_limit_every_day && has_no_limit_setting))
              break if self_pick_up.present? && self_pick_orders_limit.zero?

              if self_pick_up.present?
                break if Rails.cache.redis.get(MagicBean::Order::SELF_PICK_ORDER_LIMIT_REDIS_KEY % {self_pick_up_id: self_pick_up_id, delivery_date: earliest_delivery_date}).to_i < self_pick_orders_limit
              else
                if @available_delivery_time.limited_by_orders_limit_every_day
                  distinct_address_count = Rails.cache.redis.get(MagicBean::Order::MERCHANT_ADDRESSES_COUNT % {store_id: store_id, delivery_date: earliest_delivery_date}).to_i
                  break unless custom_merchant_address_limit.positive? && distinct_address_count >= custom_merchant_address_limit
                else
                  distinct_address_count = Rails.cache.redis.get(MagicBean::Order::DELIVERY_TIME_ADDRESSES_COUNT % {delivery_time_id: @available_delivery_time.id, delivery_date: earliest_delivery_date}).to_i
                  break if total_address_limit > distinct_address_count
                end
              end
            end
          end

          earliest_delivery_date += 1.day
          limit += 1
          break if limit > MagicBean::Order::MAX_DELIVERY_DAY
        end
        earliest_delivery_time[:use_merchant_delivery] = true
        earliest_delivery_time[:date] = earliest_delivery_date
        earliest_delivery_time[:time] = self_pick_up.present? ? @available_delivery_time.time_period.first : @available_delivery_time.delivery_time_period_settings.first&.prefer_time
        earliest_delivery_time[:wday] = I18n.l(earliest_delivery_date, format: "%a")
      end

      earliest_delivery_time
    end

    def calculate_same_day_dispatch_date(time, site_config = nil)
      return @dispatch_date if @dispatch_date

      cot = time.strftime("%H:%M")

      # 先找比item计算出来的COT大的store COT
      cutoff_time_setting = (site_config || current_store_site_config).same_day_delivery_cutoff_time || {}

      cutoff_time = cutoff_time_setting["time"] || MagicBean::SameDayDeliveryOrder::SAME_DAY_DELIVERY_CUTOFF_TIME
      display_start_at = cutoff_time_setting["display_start_at"] || MagicBean::SameDayDeliveryOrder::SAME_DAY_DELIVERY_DISPLAY_START_AT

      # 例: 设为22:00, 截单时间点为14:00, 则从22点到第二天14:00, 可以选第二天的当日达配送
      @dispatch_date = if cutoff_time <= display_start_at && cot >= display_start_at
                         time.tomorrow.to_date
                       elsif (cutoff_time <= display_start_at && cot <= cutoff_time) || (display_start_at <= cot && cot <= cutoff_time)
                         time.to_date
                       end
    end

    def calculate_same_day_delivery_date(time, postal_code = nil, suburb = nil, self_pick_up_id = nil)
      return unless same_day_delivery?
      dispatch_date = calculate_same_day_dispatch_date(time)
      return if dispatch_date.blank?

      current_delivery_area = calculate_delivery_area(postal_code, suburb)
      self_pick_up = self_pick_up_id.present? ? MagicBean::SelfPickUp.where(support_same_day_delivery: true).find_by(id: self_pick_up_id) : nil

      @available_delivery_time ||= self_pick_up || current_delivery_area&.same_day_delivery_time

      return unless @available_delivery_time
      return unless dispatch_date.wday.to_s.in?(@available_delivery_time.weekdays)

      if self_pick_up.present?
        self_pick_orders_limit = self_pick_up.self_pick_orders_limit_every_day.to_i.abs
        # 自提点不限订单数或订单数在数额内则返回日期
        return dispatch_date if self_pick_orders_limit.zero? || Rails.cache.redis.get(MagicBean::Order::SELF_PICK_ORDER_LIMIT_REDIS_KEY % {self_pick_up_id: self_pick_up_id, delivery_date: dispatch_date}).to_i < self_pick_orders_limit
      else
        # 全站配置不限地址数
        return dispatch_date unless @available_delivery_time.limited_by_orders_limit_every_day
        # 当日达订单只比对地址数, distinct_address_count包含了当日达订单
        distinct_address_count = Rails.cache.redis.get(MagicBean::Order::MERCHANT_ADDRESSES_COUNT % {store_id: store_id, delivery_date: dispatch_date}).to_i
        return dispatch_date if merchant_delivery_address_limit.zero? || (merchant_delivery_address_limit.positive? && distinct_address_count < merchant_delivery_address_limit)
      end
    end

    def show_on_sale_soon_tag
      advance_on? && start_selling_at > Time.current
    end

    def human_storage_method
      self.class.human_enum_name(:storage_method, storage_method)
    end

    MagicBean::FreightTemplate.delivery_types.keys.each do |delivery_type|
      define_method "#{delivery_type}_freight_template_id" do
        default_freight_templates.detect { |t| t.public_send "#{delivery_type}?" }&.id
      end
    end

    def admin_detail_url
      @admin_detail_url ||= "#{url_origin}/admin/stores/#{store_id}/items/#{id}"
    end

    def app_share_url
      @app_share_url ||= "#{url_origin}/app_shares?type=productDetail&id=#{id}"
    end

    def url_origin
      @url_origin ||= Rails.application.credentials.dig(Rails.env.to_sym, :domain)
    end

    def generate_change_log(params)
      log_message = []

      if !new_record?
        # 标题
        new_title_zh_cn = params["title_zh_cn"]&.strip
        if new_title_zh_cn.present? && new_title_zh_cn.to_s != title_zh_cn.to_s
          log_message << "标题（简中）从 #{title_zh_cn} 改为 #{new_title_zh_cn}"
        end

        # 上架类型
        new_listing_type = params["listing_type"]
        new_start_selling_at = params["start_selling_at"]&.in_time_zone
        if new_listing_type.present?
          if new_listing_type != listing_type
            listing_type_message = "商品上架类型从 #{I18n.t("attributes.item/listing_types.#{listing_type}")} 更改为 #{I18n.t("attributes.item/listing_types.#{new_listing_type}")}"
            if new_listing_type == "advance_on" && new_start_selling_at.present?
              listing_type_message += ", 开卖时间为 #{new_start_selling_at}"
            end

            log_message << listing_type_message
          elsif new_listing_type == "advance_on" && new_start_selling_at.present? && new_start_selling_at != start_selling_at
            log_message << "商品开卖时间从 #{start_selling_at.in_time_zone} 更改为 #{new_start_selling_at}"
          end
        end

        new_is_seasonal = params["is_seasonal"]
        if !new_is_seasonal.nil?
          if new_is_seasonal != is_seasonal
                is_seasonal_message = "是否时令商品从 #{is_seasonal ? "是" : "否"} 更改为 #{new_is_seasonal ? "是" : "否"}"
                log_message << is_seasonal_message
          end
        end

        new_is_fresh_daily = params["is_fresh_daily"]
        if !new_is_fresh_daily.nil?
          if new_is_fresh_daily != is_fresh_daily
                is_fresh_daily_message = "是否每日鲜商品从 #{is_fresh_daily ? "是" : "否"} 更改为 #{new_is_fresh_daily ? "是" : "否"}"
                log_message << is_fresh_daily_message
          end
        end

        # 预售
        new_is_presell = params["is_presell"]
        new_presell_end_at = params["presell_end_at"]&.in_time_zone
        new_presell_dispatch_on = params["presell_dispatch_on"].to_s
        new_latest_presell_dispatch_on = params["latest_presell_dispatch_on"].to_s
        if !new_is_presell.nil?
          if new_is_presell != is_presell
            presell_message = "商品预售状态从 #{is_presell ? "是" : "否"} 更改为 #{new_is_presell ? "是" : "否"}"
            if new_is_presell
              presell_message += ", 商品预售结束时间为 #{new_presell_end_at}, 预售可派送最早日期为 #{new_presell_dispatch_on}, 预售可派送最晚日期为 #{new_latest_presell_dispatch_on}"
            end
            log_message << presell_message
          elsif new_is_presell
            presell_messages = []
            if new_presell_end_at != presell_end_at
              presell_messages << "商品预售结束时间从 #{presell_end_at} 更改为 #{new_presell_end_at}"
            end
            if new_presell_dispatch_on != presell_dispatch_on.to_s
              presell_messages << "预售可派送最早日期从 #{presell_dispatch_on} 更改为 #{new_presell_dispatch_on}"
            end
            if new_latest_presell_dispatch_on != latest_presell_dispatch_on.to_s
              presell_messages << "预售可派送最晚日期从 #{latest_presell_dispatch_on} 更改为 #{new_latest_presell_dispatch_on}"
            end
            log_message << presell_messages.join(", ") if presell_messages.present?
          end
        end
      end

      log_message.join("，")
    end

    def in_time_limited_promotion?
      in_time_limited_promotion.value == "true"
    end

    def update_in_time_limited_promotion_info
      self.in_time_limited_promotion = on_sale_skus.map { |sku| sku.current_time_limited_promotion_price.present? }.any?
      if in_time_limited_promotion?
        self.tag_list.add(*MagicBean::TimeLimitedPromotion::TAGS)
      else
        self.tag_list.remove(*MagicBean::TimeLimitedPromotion::TAGS)
      end
      save
    end

    def item_banner
      MagicBean::ItemBanner.active.where("item_ids @> ARRAY[?]::integer[]", [id]).order(created_at: :desc).last
    end

    def display_expiration_date?
      return false unless show_expiration_date? && days_ahead_to_show_expiration.to_i.positive? && expiration_date.present?

      Date.today.between?(expiration_date - days_ahead_to_show_expiration, expiration_date)
    end

    # 更新SKU时需要判断，但sku完全更新之后才会更新item quantity, 所以这里不判断quantity
    def can_set_sku_valid_inventory_dates?
      advance_on? && start_selling_at.to_date <= Date.current || online?
    end

    # 同步到Elasticsearch会用到这个方法，下架、仅用作赠品、软删除的商品不同步
    def should_index?
      !pending? && !gift_only && !deleted_at?
    end

    def in_stock?
      quantity.positive?
    end

    # ES搜索布尔值无法排序，所以改用数字
    def in_stock_sort
      in_stock? ? 1 : 0
    end

    # searchkick会用这个方法，将对应数据同步到Elasticsearch，后续的搜索都要依赖于这里面的数据
    def search_data
      {
        translated_searchable_title: translated_searchable_title,
        # ES限制UTF8编码长度不能超过32766字符(中文字符10922), 这里对描述进行截取
        translated_searchable_description: (translated_searchable_description || "")[0..10911],
        tags_name: tags.map(&:name).join(" "),
        web_category_search_keywords: web_category&.search_keywords,
        category_search_keywords: category&.search_keywords,
        store_id: store_id,
        brand_id: brand_id,
        brand_name: brand&.name,
        category_name: category&.name,
        web_category_name: web_category&.name,
        minor_category_name: minor_category&.name,
        category_id: category_id,
        web_category_id: web_category_id,
        parent_category_id: parent_category_id,
        parent_web_category_id: parent_web_category_id,
        minor_category_id: minor_category_id,
        minor_web_category_id: minor_web_category_id,
        minor_category_parent_id: minor_category&.parent_id,
        minor_web_category_parent_id: minor_web_category&.parent_id,
        in_stock: in_stock?,
        in_stock_sort: in_stock_sort,
        free_shipping: free_shipping,
        channels: channels,
        custom_list_ids: custom_list_ids,
        web_custom_list_ids: web_custom_list_ids,
        created_at: created_at,
        special_offer: strikethrough_price_in_cent.to_i > price_in_cent.to_i,
        sales_count: sales_count,
        display_sales_count: display_sales_count,
        price_in_cent: price_in_cent,
        delivery_types: delivery_type,
        position: position,
        item_type: item_type,
        storage_method: storage_method,
        first_sale_at: first_sale_at,
        freight_type: freight_type
      }
    end

    # class methods
    class << self
      def es_connected?
        false
        # settings = Searchkick.client.transport.hosts.first
        # path = "#{settings[:protocol]}://#{settings[:host]}:#{settings[:port]}/_cluster/health"
        # # 如果ES服务到期，Item.search会占用很长搜索时间，而且无法传timeout参数
        # # 所以先检测链接是否正常，再搜索任意一条数据来搜索是否可用
        # begin
        #   RestClient::Request.execute(method: :get, url: path, user: settings[:user], password: settings[:password], timeout: 0.5)
        #   MagicBean::Item.search("*", limit: 1)
        #   true
        # rescue
        #   false
        # end
      end

      def es_search(params, page = 1, per_page = 25, offset = 0)
        fields = ES_SEARCH_FIELDS
        channel = params[:channel]
        and_conditions = [{ store_id: params[:store_id] }, { channels: [channel] } ]
        order_by = if params[:new_product_custom_list]
          { in_stock_sort: :desc, _score: :desc, first_sale_at: :desc }
        else
          { in_stock_sort: :desc, _score: :desc, position: :asc, created_at: :desc }
        end

        custom_list_id = params[:custom_list_id]
        if channel == "web"
          fields += ["web_category_name^2", "web_category_search_keywords^4"]
          and_conditions << { web_custom_list_ids: [custom_list_id] } if custom_list_id.present?
        else
          and_conditions << { custom_list_ids: [custom_list_id] } if custom_list_id.present?
          fields += ["category_name^2", "category_search_keywords^4"]
        end

        and_conditions << { in_stock: params[:in_stock] } unless params[:in_stock].nil?
        and_conditions << { free_shipping: params[:free_shipping] } unless params[:free_shipping].nil?
        and_conditions << { special_offer: params[:special_offer] } unless params[:special_offer].nil?
        and_conditions << { delivery_types: params[:delivery_types] } unless params[:delivery_types].nil?
        and_conditions << { created_at: { gte: params[:created_at_gteq] } } if params[:created_at_gteq].present?
        and_conditions << { first_sale_at: { gte: params[:first_sale_at_gteq] } } if params[:first_sale_at_gteq].present?
        and_conditions << { price_in_cent: { gte: params[:price_in_cent_gteq] } } if params[:price_in_cent_gteq].present?
        and_conditions << { price_in_cent: { lte: params[:price_in_cent_lteq] } } if params[:price_in_cent_lteq].present?
        and_conditions << { storage_method: params[:storage_method_in] } if params[:storage_method_in].present?
        and_conditions << { item_type: params[:item_type_eq] } if params[:item_type_eq].present?
        and_conditions << { freight_type: params[:freight_type_eq] } if params[:freight_type_eq].present?
        and_conditions << { brand_id: params[:brand_id_in] } if params[:brand_id_in].present?

        # 处理分类查询
        if params[:minor_or_category_id].present?
          and_conditions <<  { _or: [{ category_id: params[:minor_or_category_id] }, { minor_category_id: params[:minor_or_category_id] }] }
        end

        if params[:minor_or_web_category_id].present?
          and_conditions <<  { _or: [{ web_category_id: params[:minor_or_web_category_id] }, { minor_web_category_id: params[:minor_or_web_category_id] }] }
        end

        if params[:minor_or_category_parent_id].present?
          and_conditions <<  { _or: [{ parent_category_id: params[:minor_or_category_parent_id] }, { minor_category_parent_id: params[:minor_or_category_parent_id] }] }
        end

        if params[:minor_or_web_category_parent_id].present?
          and_conditions <<  { _or: [{ parent_web_category_id: params[:minor_or_web_category_parent_id] }, { minor_web_category_parent_id: params[:minor_or_web_category_parent_id] }] }
        end

        and_conditions <<  { category_id: { not: params[:category_id_not_in] } } if params[:category_id_not_in].present?

        sort_item_ids = params[:sort_item_ids]
        if sort_item_ids.present?
          and_conditions << { id: sort_item_ids }

          # 按照指定的 ID 值顺序对搜索结果进行排序
          id_positions = {}
          sort_item_ids.each_with_index { |id, idx| id_positions[id] = idx }

          order_options = {
            "type" => "number",
            "script" => {
              "source" => "params.idPositions.containsKey(doc['_id'].value) ? params.idPositions[doc['_id'].value] : params.ids.size()",
              "params" => { "ids" => sort_item_ids, "idPositions" => id_positions }
            },
            "order" => "asc"
          }
          # 重置order_by
          order_by = { "_script": order_options }
        # sort_item_ids 和 id_in不会同时出现
        elsif params[:id_in].present?
          and_conditions << { id: params[:id_in] }
        end

        if params[:order_by].present?
          order_by = format_es_order_by(params[:order_by])
        end

        # 测试了多种情况，设置最低分数为50先
        # 如果没有输入关键字，则将最低分数设为0.01，因为如果只是查询分类，计分只有1分
        min_score = params[:keyword] == "*" ? 0.01 : ES_MIN_SCORE

        # 如果传了offset，会导致page失效，数据一直拿的第一页，所以这个接口我们以offset为准，这里如果offset为0时重新计算offset
        offset = (page - 1) * per_page if offset.zero?

        # 发现简体和繁体搜索到的结果会不一样，所以搜索内容改为简繁体一起搜
        # TODO: 原方案是传多keyword数组，将简体繁体都传过去，查询多个keyword的合集，但实测传数组为and查询，需要再调研如何改写
        # 调试发现繁体搜索结果比简体更准确些，先把keyword转成繁体作为替代方案先
        search(
          format_search_keyword(params[:keyword], channel),
          where: {_and: and_conditions},
          body_options: { min_score: min_score },
          fields: fields.uniq,
          order: order_by,
          includes: params[:includes],
          page: page,
          per_page: per_page,
          offset: offset
        )
      end

      def es_autocomplete(keyword, store_id, channel, delivery_types, item_type_eq = nil, page = 1, per_page = 25)
        and_conditions = [{ store_id: store_id }, { channels: [channel] } ]
        and_conditions << { item_type: item_type_eq } if item_type_eq.present?
        and_conditions << { delivery_types: delivery_types } unless delivery_types.nil?

        fields = ES_SEARCH_FIELDS
        if channel == "web"
          fields += ["web_category_name^2", "web_category_search_keywords^4"]
        else
          fields += ["category_name^2", "category_search_keywords^4"]
        end

        search(
          format_search_keyword(keyword, channel),
          where: { _and: and_conditions },
          body_options: { min_score: ES_MIN_SCORE }, # 只返回分数大于50的结果
          fields: fields.uniq,
          limit: 20,
          misspellings: { below: 5 }, # 允许拼错5个字符
          order: { _score: :desc },
          page: page,
          per_page: per_page,
        ).map(&:title).uniq
      end

      def format_es_order_by(order_by_arr)
        order_clause = {}
        order_by_arr.each do |order_by_str|
          column, direction = order_by_str.split(" ")
          order_clause[column.to_sym] = direction&.to_sym || :asc
        end
        order_clause
      end

      def format_search_keyword(keyword, channel)
        if channel == "app"
          Ropencc.conv("s2tw.json", keyword)
        else
          keyword
        end
      end
    end

    def sync_sku_attrs
      # 因为 stock_keeping_unit model 的 after_commit 执行完其中一个 item update sql 后，saved_changes 会清空。
      # 所以提供一个手动同步的方法
      sku_quantity = on_sale_skus.sum(:quantity)
      minimun_new_user_price_in_cent = on_sale_skus.minimum(:new_user_price_in_cent)
      minimun_normal_price_in_cent = on_sale_skus.minimum(:price_in_cent).to_i
      minimun_normal_strikethrough_price_in_cent = on_sale_skus.minimum(:strikethrough_price_in_cent)

      minimun_promotion_price = MagicBean::TimeLimitedPromotionPrice.active.where(stock_keeping_unit_id: on_sale_skus.ids).minimum(:price_in_cent)

      if minimun_promotion_price.present?
        # 有限时优惠时单独处理最低售价和划线价
        minimun_price_in_cent = [minimun_normal_price_in_cent, minimun_promotion_price].min
        minimun_strikethrough_price_in_cent =
          if minimun_normal_strikethrough_price_in_cent.blank? && minimun_price_in_cent != minimun_normal_price_in_cent
            minimun_normal_price_in_cent
          else
            minimun_normal_strikethrough_price_in_cent
          end

        self.update_columns(
          quantity: sku_quantity,
          price_in_cent: minimun_price_in_cent,
          strikethrough_price_in_cent: minimun_strikethrough_price_in_cent,
          new_user_price_in_cent: minimun_new_user_price_in_cent
        )
      else
        self.update_columns(
          quantity: sku_quantity,
          price_in_cent: minimun_normal_price_in_cent,
          strikethrough_price_in_cent: minimun_normal_strikethrough_price_in_cent,
          new_user_price_in_cent: minimun_new_user_price_in_cent
        )
      end
    end

    def maximun_strikethrough_price_in_cent
      on_sale_skus.maximum(:strikethrough_price_in_cent)
    end

    def aliexpress_synced?
      ae_item.present?
    end

    def aliexpress_syncable?
      channel_match?("aliexpress") || aliexpress_synced?
    end

    def shopline_synced?
      shopline_item.present?
    end

    def shopline_syncable?
      channel_match?("shopline") || shopline_synced?
    end

    def shopline_create_item
      return unless channel_match?("shopline")
      return if on_sale_skus.blank?

      product_reponse = Shopline::Api.create_product(self)
      raise product_reponse["errors"] if product_reponse["errors"].present?

      shopline_product_id = product_reponse["product"]["id"]
      build_shopline_item(third_party_id: shopline_product_id).save!

      # 更新shopline元字段
      UpdateShoplineProductMetafieldsJob.perform_later(id, shopline_product_id)

      shopline_skus = product_reponse["product"]["variants"]
      on_sale_skus.each do |sku|
        target_sku = shopline_skus.select { |shopline_sku| shopline_sku["sku"] == sku.no }.first
        third_party_sku = sku.build_shopline_sku(third_party_id: target_sku["id"], third_party_inventory_item_id: target_sku["inventory_item_id"])
        third_party_sku.save

        # 先绑定库存地点
        ConnectShoplineInventoryJob.perform_later(target_sku["inventory_item_id"], peti_store?)
        # 更新库存需要绑定库存地点成功后才能更新成功，所以这里一分钟后再触发job
        UpdateShoplineInventoryJob.set(wait: 1.minute).perform_later(sku.id)
      end
    end

    def shopline_update_item(job_name = nil, job_arg_id = nil)
      return unless shopline_synced?
      product_reponse = Shopline::Api.update_product(self, shopline_item.third_party_id)

      # 这里出现太多too many requests错误，所以遇到该报错，1分钟后重试，其他报错直接raise
      reponse_errors = product_reponse["errors"]
      if reponse_errors.present?
        if reponse_errors.include?("Too many request") && job_name.present?
          job_name.constantize.set(wait: 1.minute).perform_later(job_arg_id)
          return
        else
          raise reponse_errors
        end
      end

      # 如果产品channels移除了shopline，则无需执行后续操作
      return unless channel_match?("shopline")

      # 更新shopline元字段
      UpdateShoplineProductMetafieldsJob.perform_later(id, shopline_item.third_party_id)

      shopline_skus = product_reponse["product"]["variants"]
      on_sale_skus.each do |sku|
        # sku修改了规格名会导致shopline sku id变化，所以需要重新绑定
        update_stock = true

        target_sku = shopline_skus.select { |shopline_sku| shopline_sku["sku"] == sku.no }.first
        if sku.shopline_synced?
          # 如果third_party_id和third_party_inventory_item_id没变化就无需更新
          current_shopline_sku = sku.shopline_sku
          if target_sku["id"] == current_shopline_sku.third_party_id && target_sku["inventory_item_id"] == current_shopline_sku.third_party_inventory_item_id
            update_stock = false
          else
            current_shopline_sku.update(third_party_id: target_sku["id"], third_party_inventory_item_id: target_sku["inventory_item_id"])
          end
        else
          third_party_sku = sku.build_shopline_sku(third_party_id: target_sku["id"], third_party_inventory_item_id: target_sku["inventory_item_id"])
          third_party_sku.save
        end
        
        # 新增的sku更新库存
        UpdateShoplineInventoryJob.set(wait: 10.seconds).perform_later(sku.id) if update_stock
      end
    end

    # 分类不需要同步，该方法暂时弃用
    # 绑定shopline分类
    def bind_shopline_category(shopline_product_id)
      shopline_category_id = category.shopline_category.third_party_id
      Shopline::Api.product_bind_category(shopline_product_id, shopline_category_id, peti_store?)
    end

    # shopline的商品链接由handle控制，handle长度最长255
    def shopline_handle
      # 移除标点符号，把空格替换为-, 并移除连续的-
      sanitized_title = title_en.gsub(/[^\w\s]/, ' ').strip.gsub(/\s+/, '-').gsub(/-+/, '-')
      "#{id}-#{sanitized_title.first(240)}"
    end

    # 目前只更新SKU库存和产品销量、is_ae_choice、上架状态
    def update_ae_item
      return unless ae_drop_shipper
      retry_times = 3

      begin
        detail_response = Aliexpress::Api.get_dropshipper_product_detail(no)

        rsp_code = detail_response.body.dig("rsp_code")
        if rsp_code.in?(AE_UNSALEABLE_CODE)
          return true if pending? && ae_unsaleable
          ae_unsaleable_offline!
          MagicBean::OperationRecord.create(operatable: self, content: "同步下架不可销售AE产品，no: #{no}", store_id: store_id, channel: "admin")
          return false
        end
  
        product_result = detail_response.body.dig("result")

        sydney_store ||= MagicBean::Store.sydney
        # 进货价最小倍数
        ae_sku_cost_minimum_factor = sydney_store.site_config&.ae_sku_cost_minimum_factor
        
        item_info = product_result["ae_item_base_info_dto"]
        item_properties = product_result["ae_item_properties"]
        is_ae_choice = item_properties.any? {|property| property["attr_name_id"] == -1 && property["attr_name"] == "Choice" && property["attr_value"] == "yes" }
        skus_info = product_result["ae_item_sku_info_dtos"]
        package_info = product_result["package_info_dto"]

        newest_sku_nos = skus_info.map do |sku|
          next if sku["id"].blank?
          sku["sku_id"]
        end.compact

        # 格式化成{no: id}
        existed_sku_hash = {}
        stock_keeping_units.each do |sku|
          existed_sku_hash[sku.no] = sku.id
        end

        existed_sku_nos = existed_sku_hash.keys

        # 下架的sku货号
        offline_sku_nos = existed_sku_nos - newest_sku_nos

        stock_keeping_units_attributes = []

        skus_info.each do |sku|
          next if sku["id"].blank?

          # offer_sale_price: 折扣后的价格
          # sku_price: 原价
          ae_price = sku["offer_sale_price"].presence || sku["sku_price"]
          if ae_sku_cost_minimum_factor.present?
            # 售价和划线价乘最小倍数
            sale_price = (ae_price.to_f * ae_sku_cost_minimum_factor).round(2)
            strikethrough_price = (sku["sku_price"].to_f * ae_sku_cost_minimum_factor).round(2)
          else
            sale_price = ae_price
            strikethrough_price = sku["sku_price"]
          end

          # 如果划线价小于等于售价，则划线价为空
          strikethrough_price = nil if strikethrough_price <= sale_price

          # 更新的sku
          if sku["sku_id"].in?(existed_sku_nos)
            stock_keeping_units_attributes << {
              id: existed_sku_hash[sku["sku_id"]],
              quantity: sku["sku_available_stock"],
              price_in_yuan: sale_price,
              strikethrough_price_in_yuan: strikethrough_price,
              ae_price_in_yuan: ae_price,
            }
          else
            # 新增的sku
            sku_properties = sku["ae_sku_property_dtos"]
  
            properties = sku_properties.map do |property|
              sku_property_str = property["sku_property_name"]&.strip
              sku_value_str = property["sku_property_value"]&.strip
              sku_definition_name = property["property_value_definition_name"]&.strip
    
              sku_value_str = "#{sku_value_str}(#{sku_definition_name})" if sku_definition_name.present? && sku_value_str != sku_definition_name
    
              # 将规格名跟普通商品区分开，加上ae_property_id
              sku_property = MagicBean::SkuProperty.find_or_create_by(text: sku_property_str, ae_property_id: property["sku_property_id"])
              # 1005005453331843返回的数据出现了规格值完全一样，但id不一样的情况，所以需要把property_value_id也带上
              sku_value = sku_property.sku_values.find_or_create_by(text: sku_value_str, ae_property_value_id: property["property_value_id"])
              "#{sku_property.id}:#{sku_value.id}"
            end.join(";")

            # 出现了一个场景：新增的sku的properties是已经存在，但no不一样，也就是sku货号发生了变更
            exist_sku = stock_keeping_units.find_by(properties: properties)
            offline_sku_nos -= [exist_sku.no] if exist_sku.present?

            stock_keeping_units_attributes << {
              id: exist_sku&.id,
              no: sku["sku_id"], # 用ae sku_id
              ae_sku_attr: sku["sku_attr"], # 下单需要用到该字段
              properties: properties,
              price_in_yuan: sale_price,
              strikethrough_price_in_yuan: strikethrough_price,
              ae_price_in_yuan: ae_price,
              quantity: sku["sku_available_stock"],
              gst_percent: 0,
              marketing_mode: "consign_for_sale",
              image: sku_properties.first["sku_image"],
              barcode: sku["sku_id"], # 用sku_id
              weight_in_gram: (package_info["gross_weight"].to_f * 1000).round, # 返回的单位是kg
              length_in_cm: package_info["package_length"],
              width_in_cm: package_info["package_width"],
              height_in_cm: package_info["package_height"],
              on_sale: true,
              is_special: false,
            }
          end
        end

        # offline_sku_nos有的已经下架过了，不需要再记录操作记录
        updated_offline_sku_nos = []

        stock_keeping_units.where(on_sale: true, no: offline_sku_nos).each do |sku|
          stock_keeping_units_attributes << {
            id: sku.id,
            on_sale: false,
          }

          updated_offline_sku_nos << sku.no
        end

        item_attributes = {
          sales_count: item_info["sales_count"],
          is_ae_choice: is_ae_choice,
          stock_keeping_units_attributes: stock_keeping_units_attributes,
          ae_unsaleable: false,
          ae_basic_info_last_updated_date: Date.current,
        }

        if item_info["product_status_type"] != "onSelling"
          item_attributes[:listing_type] = "pending"
          item_attributes[:ae_unsaleable] = true
        end

        if update(item_attributes) && updated_offline_sku_nos.present?
          # 下架SKU需要记录操作记录
          MagicBean::OperationRecord.create(operatable: self, content: "同步更新AE产品，下架SKU货号: #{updated_offline_sku_nos.join(", ")}", store_id: store_id, channel: "admin")
        end
      rescue => e
        retry_times -= 1
        retry_times > 0 ? retry : false
      end
    end

    # 更新AE商品配送日期和免运费门槛
    def update_ae_choice_delivery_date_and_free_shipping_threshold
      return false unless ae_drop_shipper
      
      # 用第一个有库存的sku作为配送日期计算
      sku = stock_keeping_units.where("quantity > 0").first
      return false if sku.blank?
      retry_times = 2

      begin
        freight_info = Aliexpress::Api.freight_query(no, sku.no)
        result = freight_info.body["result"]
        # 如果SKU库存为0，会返回{"msg"=>"DELIVERY_NOT_AVAILABLE_TO_YOUR_ADDRESS", "code"=>505, "success"=>false}
        # AE的商品详情接口的库存不是实时的，所以这里要下架商品
        # 还看到有错误信息是 {"msg"=>"DELIVERY_INFO_EMPTY", "code"=>501, "success"=>false}，这里直接把不是200错误码都下架
        if result["code"] != 200
          ae_unsaleable_offline!
          return false
        end

        delivery_option = result["delivery_options"].first
        ae_delivery_date_desc = delivery_option["delivery_date_desc"]
        ae_delivery_date = ae_delivery_date_desc.split(" - ").first.to_date
        ae_delivery_date += 1.year if ae_delivery_date < Date.current
        free_shipping_threshold = (delivery_option["free_shipping_threshold"]&.split("$")&.last.to_f * 100).round

        update_columns(
          ae_delivery_date_desc: ae_delivery_date_desc,
          ae_delivery_date: ae_delivery_date,
          ae_estimated_delivery_days: delivery_option["estimated_delivery_time"],
          ae_free_shipping_threshold_in_cent: free_shipping_threshold,
          ae_shipping_info_last_updated_date: Date.current
        )
      rescue => e
        retry_times -= 1
        retry_times > 0 ? retry : false
      end
    end

    def soft_delete!
      suffix = "-deleted-#{Time.current.to_i}"
      update!(deleted_at: Time.current, listing_type: :pending, no: "#{no}#{suffix}")
      stock_keeping_units.update_all("no = concat(no, '#{suffix}'), barcode = concat(barcode, '#{suffix}')")
    end

    def ae_unsaleable_offline!
      update!(listing_type: :pending, ae_unsaleable: true)
    end

    def active_top_left_item_tag_icon
      MagicBean::TopLeftItemTag.active.where("item_ids @> ARRAY[?]::integer[]", id).first&.icon
    end

    # 首次开卖在30天内，或再次开卖在30天内，且暂不售卖时间大于等于180天
    def is_new_product?
      return false if first_sale_at.blank? && last_sale_at.blank? && last_offline_at.blank?
      (first_sale_at.present? && first_sale_at >= 1.month.ago.beginning_of_day) || (last_sale_at.present? && last_offline_at.present? && last_sale_at >= 1.month.ago.beginning_of_day && last_offline_at <= 180.days.ago.beginning_of_day)
    end

    # 获取WMS库存
    def get_skus_wms_stock
      # 非普通或当日达产品不请求WMS库存
      # 非自营产品不请求WMS库存
      return [] if !(normal? || same_day_delivery?) || ae_drop_shipper      

      response = Ewe::Eparcel.skus_stock(self)
      return [] unless response["Status"] == 0
      response.dig("Payload")&.map do |sku|
        # 只需要返回conditionCode是Available的数据
        next unless sku.dig("conditionCode") == "Available"
        
        {
          id: sku["RetailSKU"],
          quantity: sku["Quantity"]
        }
      end&.compact || []
    end

    private

    def check_sales_count
      return if sales_count.zero?

      intersection = %w[item_type] & changes.keys
      # 限制拍卖商品不能修改产品类型
      return if intersection.empty? || changes["item_type"].exclude?("auction")
      intersection.each do |name|
        errors.add(:base, "已售出商品不允许修改#{I18n.t("activerecord.attributes.magic_bean/item.item_type")}")
      end
    end

    def set_price_in_cent
      self.price_in_cent = on_sale_skus.map(&:price_in_cent).min
    end

    # 生成二维码需要的参数
    def qrcode_params
      {
        sence: "id=#{id}",
        path: "pages/products/detail/detail",
      }
    end

    def validate_freight_templates
      delivery_type&.each do |d_t|
        freight_method = "#{d_t}_freight_template_id"
        errors.add(freight_method.to_sym, "请选择对应的运费模版") if self.public_send(freight_method).blank?
      end
    end

    def should_update_skus_updated_at?
      UPDATE_SKU_COLUMNS.select { |column| send "saved_change_to_#{column}?" }.any?
    end

    def update_skus_updated_at
      stock_keeping_units.update_all(updated_at: Time.current)
    end

    def try_set_skus_first_sale_time
      return if pending?

      # 批量上架时，可能会只更新 item 的上架状态，所以需要手动更新 sku 的上架时间
      stock_keeping_units.each do |sku|
        # 只更新item的时候才需要save, 不然会导致stock_keeping_unit的saved_changes为空
        if sku.saved_changes.present?
          sku.try_set_first_sale_time
        else
          # 减少save次数，只处理first_sale_at为空的SKU
          next if sku.first_sale_at.present?
          sku.try_set_first_sale_time
          sku.save
        end
      end
    end

    def set_last_sale_at_and_last_offline_at
      # 如果first_sale_at为空，则last_sale_at和last_offline_at都为空
      return if first_sale_at.blank?

      if online?
        self.last_sale_at = Time.current
      elsif advance_on?
        self.last_sale_at = start_selling_at
      else
        self.last_offline_at = Time.current
      end
    end

    # 现在只允许设置一个截单时间
    def target_cutoff_time
      cutoff_times.first
    end

    def destroy_product
      product.destroy if product.items.where.not(id: id).blank?
    end

    def set_display_sales_count
      self.display_sales_count = calculate_display_sales_count
    end

    def set_no
      return if no.present?
      loop do
        self.no = SecureRandom.hex(4)
        break unless self.class.exists?(no: no)
      end
    end

    def set_delivery_type
      return unless is_virtual
      self.delivery_type = [:virtual_delivery]
      self.freight_type = :freight_fixed
      self.fixed_freight = 0
      self.delivery_weekdays = []
    end

    def format_title_and_description
      self.title_zh_cn = title_zh_cn&.strip
      self.title_zh_tw = title_zh_tw&.strip
      self.title_en = title_en&.strip
    end

    def check_category_id
      errors.add(:base, "不能直接绑定一级分类") if category && category.parent_id.nil?
    end

    def check_channels
      errors.add(:base, "平台限制不能为空") if channels.blank?
    end

    def presell_dispatch_on_valid?
      errors.add(:base, "预售可派送最早日期不可大于预售可派送最晚日期") if presell_dispatch_on.present? && latest_presell_dispatch_on.present? && presell_dispatch_on > latest_presell_dispatch_on
    end

    def enqueue_presell_item_pending_job
      SetPresellItemPendingJob.set(wait_until: presell_end_at).perform_later(id)
    end

    def enqueue_sku_in_stock_notice_job
      if listing_type_previously_changed? && listing_type_previous_change[0] == "pending" && listing_type_previous_change[1] == "online"
        stock_keeping_units.on_sale.each do |sku|
          SendSkuInStockNoticeJob.perform_later(sku.id) if sku.quantity.positive? && sku.sku_in_stock_notices.pending.any?
        end
      end
    end

    def current_store_site_config
      @current_store_site_config ||= store.site_config
    end

    def merchant_delivery_address_limit
      @merchant_delivery_address_limit ||= Rails.cache.redis.get("store-#{store_id}-orders-limit-every-day").to_i
    end

    def set_parent_category
      self.parent_category_id = category&.parent_id if category.present? || category_id_changed?
      self.parent_web_category_id = web_category&.parent_id if web_category.present? || web_category_id_changed?
    end

    def reset_presell_date_time
      self.presell_end_at = nil
      self.presell_dispatch_on = nil
      self.latest_presell_dispatch_on = nil
    end

    def enqueue_sync_wms_product_job
      SyncWMSProductJob.perform_later(self)
    end

    def set_i18n_attributes
      %w[title description shared_description].each do |attr|
        text_zh_cn = send("#{attr}_zh_cn")
        if text_zh_cn.present?
          self.send("#{attr}_zh_tw=", Ropencc.conv("s2tw.json", text_zh_cn)) if send("#{attr}_zh_tw").blank?
          self.send("#{attr}_en=", EasyTranslate.translate(text_zh_cn, from: :"zh-CN", to: :en)) if send("#{attr}_en").blank?
        end
      end
    end

    def translate_fields_with_zh_tw
      changed_keys = changes.keys

      %w[title description shared_description].each do |attr|
        next if changed_keys.include?("#{attr}_zh_tw")

        text_zh_cn = send("#{attr}_zh_cn")
        if text_zh_cn.present? && send("#{attr}_changed?")
          self.send("#{attr}_zh_tw=", Ropencc.conv("s2tw.json", text_zh_cn))
        end
      end
    end

    def set_translated_searchable_attrs
      self.translated_searchable_title = [title_zh_cn, title_zh_tw, title_en].compact.join(" ")
      self.translated_searchable_description = [description_zh_cn, description_zh_tw, description_en].compact.join(" ")
    end

    def at_least_one_sku_if_change_to_sale
      if listing_type_changed?(to: "online") || listing_type_changed?(to: "advance_on")
        on_sale_sku_length = 0
        stock_keeping_units.each { |sku| on_sale_sku_length += 1 if sku.on_sale }
        self.errors.add(:base, "至少需要一个 SKU 上架") if on_sale_sku_length.zero?
      end
    end

    def check_same_day_delivery_valid
      errors.add(:base, "当日达商品只支持商家配送和自提") if (delivery_type & ["express", "virtual_delivery"]).present?
      errors.add(:base, "预售商品不可设置为当日达") if is_presell
      errors.add(:base, "当日达商品不可设置截止时间") if cutoff_times.present?
      errors.add(:base, "当日达商品不可设置可配送星期数") if delivery_weekdays.present?
    end

    # 当产品类型从当日达变为普通商品时，需要清除当日达购物车该商品的数据
    def clear_same_day_delivery_cart_items
      if item_type_previous_change == ["same_day_delivery", "normal"]
        MagicBean::SameDayDeliveryCartItem.where(stock_keeping_unit_id: stock_keeping_unit_ids).delete_all
      end
    end

     # 当产品gift_only从true变为false，需要清除购物车该商品的数据
     # FIXME: 当前的购物车接口没有拿redis数据，所以这里删除数据先不触发清除购物车缓存方法
    def clear_gift_only_cart_items
      if gift_only_previous_change == [false, true]
        MagicBean::ShoppingCartItem.where(stock_keeping_unit_id: stock_keeping_unit_ids).delete_all
      end
    end

    def sort_and_set_delivery_weekdays
      self.delivery_weekdays = sorted_delivery_weekdays
    end

    def sorted_delivery_weekdays
      delivery_weekdays.sort do |x, y|
        if x == "0" || y == "0" # 0 是周日，周日需要排最后
          1
        else
          x <=> y
        end
      end
    end

    # 修改了上架类型，只要是上架状态就需要更新有效库存日期
    def set_sku_valid_inventory_dates
      # 自定义上架产品的上架时间大于或等于今天，或是立即上架产品，且数量大于 0
      if can_set_sku_valid_inventory_dates? && in_stock?
        on_sale_skus.each do |sku|
          # 没库存的sku不记录有效库存日期
          next unless sku.quantity.positive?
          sku.generate_valid_inventory_dates
        end
      end
    end

    def enqueue_sync_sku_attrs_job
      # 商品更新了上架状态时延时 10 秒执行一次同步 sku 售价和库存，以免数据不一致
      SyncSkuAttrsToItemJob.set(wait: 10.seconds).perform_later(id)
    end

    def custom_reindex
      if previous_changes.key?("quantity")
        # 新建或库存有变化到0的情况
        if previous_changes["quantity"].include?(nil) || (previous_changes["quantity"] - [0]).length == 1
          reindex(mode: :async)
        end
      elsif destroyed? || (previous_changes.keys & ["tag_list", "translated_searchable_title", "translated_searchable_description", "brand_id", "category_id", "web_category_id", "minor_category_id", "minor_web_category_id", "channels", "price_in_cent", "strikethrough_price_in_cent", "delivery_type", "storage_method", "listing_type", "start_selling_at", "first_sale_at"]).present?
        reindex(mode: :async)
      end
    end

    # TODO: 以下几个场景同步到aliexpress
    # 1. 创建产品且为上架状态，channel包含了aliexpress
    # 2. channel修改，aliexpress值有变动
    # 3. 产品修改上下架
    # 4. SKU新增、删除或下架，删除、下架时直接将aliexpress对应SKU的库存设置为0即可
    def sync_to_aliexpress

    end

    def enqueue_create_shopline_item_job
      # channel包含shopline或之前已经同步过才需要再次同步
      # 新建产品为上架状态时，才继续下一步
      return unless shopline_syncable? && online?
      
      SyncItemToShoplineJob.perform_later(id)
    end

    # 创建item时，由于stock_keeping_unit里面多次触发item.update, 导致该方法无法判断数据是否新建，所以将create和update逻辑分开
    def enqueue_update_shopline_item_job
      # channel包含shopline或之前已经同步过才需要再次同步
      return unless shopline_syncable?
      
      # 真实删除时这里无法拿到third_party_id，在third_party_item model中处理
      return if destroyed?
      # 如果产品为下架状态，且修改的key没有listing_type，则跳过
      return if !online? && previous_changes.keys.exclude?("listing_type")

      # 软删除归档产品
      if deleted_at?
        shopline_item.archived_shopline_product
      else
        # 以下场景触发同步
        # 1. 创建产品
        # 2. 更新标题、描述、图片、品牌、channels、listing_type、delivery_type、storage_method、show_expiration_date、days_ahead_to_show_expiration、expiration_date
        SyncItemToShoplineJob.perform_later(id) if (previous_changes.keys & ["translated_searchable_title", "translated_searchable_description", "brand_id", "channels", "listing_type", "main_images", "delivery_type", "storage_method", "show_expiration_date", "days_ahead_to_show_expiration", "expiration_date"]).present?
      end
    end

    def enqueue_update_product_metafields_job
      return if expiration_date.blank?
      SyncItemToShoplineJob.set(wait_until: expiration_date.end_of_day).perform_later(id)
    end

    # 图片来自速卖通 CDN，跳过白名单校验（与 job 的跳过条件一致）
    def resource_url_validation_enabled?
      !ae_drop_shipper
    end

    def enqueue_generate_aws_lambda_image_job
      GenerateAwsLambdaImageJob.perform_later(self.class.name, id) unless ae_drop_shipper
    end
  end
end
