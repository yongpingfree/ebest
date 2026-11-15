# frozen_string_literal: true
module MagicBean
  class CustomList < ApplicationRecord
    # scope
    default_scope { order(position: :asc) }

    # constants
    REDIS_API_KEY_NAMESPACE = "app_api_custom_list/"
    ES_KEY_REDIS_TIME = 100.minutes

    # attr related macros
    alias_attribute :name, :title

    enum kind: {
      normal: 1,
      guess_you_like: 2,
      new_product: 3 # 新品
    }

    translates :title
    globalize_accessors attributes: [:title]

    # association macros
    has_many :custom_list_items, dependent: :destroy, inverse_of: :custom_list
    has_many :on_sale_custom_list_items, -> { on_sale }, class_name: "MagicBean::CustomListItem"
    has_many :not_merchant_delivery_custom_list_items, -> { not_merchant_delivery }, class_name: "MagicBean::CustomListItem"
    has_many :items, -> { on_sale.reorder(MagicBean::CustomList.item_default_order) }, through: :custom_list_items, source: :item
    # OMS后台列表不需要排序，需要跟一开始的配置保持一致
    has_many :no_sort_items, -> { reorder(nil) }, through: :custom_list_items, source: :item
    has_many :not_merchant_delivery_items, -> { on_sale.not_merchant_delivery.reorder(MagicBean::CustomList.item_default_order) }, through: :custom_list_items, source: :item
    belongs_to :parent_category, class_name: "MagicBean::Category", optional: true

    belongs_to :store

    accepts_nested_attributes_for :custom_list_items, allow_destroy: true

    # validation macros
    validates :title_zh_cn, presence: true

    # callbacks
    before_create :set_title_i18n

    # other macros
    delegate :name, to: :store, prefix: true

    # class methods
    def self.clear_all_redis_keys
      Redis::Objects.redis.keys("#{REDIS_API_KEY_NAMESPACE}*").each do |key|
        Redis::Value.new(key).clear
      end
    end

    def self.import_from_excel(title, file_url, admin_user_id, store_id, list_id)
      xlsx = Roo::Spreadsheet.open file_url
      sheet = xlsx.sheet(0).parse
      no_exists_item_no_array = []
      error_ae_drop_shipper_no_array = []
      found_no_with_item_hash = {} # key: item_no, value: [item_id, excel_idx]
      excel_idx = 1
      es_item_ids = []

      custom_list = MagicBean::CustomList.find_by(id: list_id)

      ae_drop_shipper = custom_list&.ae_drop_shipper || false

      sheet.each_with_index do |row, i|
        no = row[0].to_s.strip
        # 新增才需要重新设置ae_drop_shipper
        ae_drop_shipper = row[2].to_s.strip == "是" if i.zero? && custom_list.blank?

        break if no.blank?

        item = MagicBean::Item.find_by no: no, store_id: store_id
        if item.present?
          if item.ae_drop_shipper != ae_drop_shipper
            error_ae_drop_shipper_no_array << no
          else
            found_no_with_item_hash[no] = [item.id, excel_idx]
            es_item_ids << item.id
            excel_idx += 1
          end
        else
          no_exists_item_no_array << no
        end
      end

      custom_list_items_attributes = []
      found_no_with_item_hash.each_pair do |item_no, item_id_with_idx|
        custom_list_items_attributes << { item_id: item_id_with_idx[0], position: item_id_with_idx[1], store_id: store_id }
      end

      if custom_list.nil?
        custom_list = MagicBean::CustomList.new(
          title_zh_cn: title, title_zh_tw: title, title_en: title,
          store_id: store_id, custom_list_items_attributes: custom_list_items_attributes,
          ae_drop_shipper: ae_drop_shipper
        )
      else
        old_item_ids = custom_list.item_ids
        es_item_ids = (old_item_ids + es_item_ids) - (old_item_ids & es_item_ids)

        # 已存在的商品列表，先删除所有商品，再重新导入
        custom_list.custom_list_items.delete_all
        custom_list.custom_list_items_attributes = custom_list_items_attributes
      end

      if custom_list.save
        # Rails.cache.write(custom_list.es_item_ids_key, ((Rails.cache.fetch(custom_list.es_item_ids_key) || []) + es_item_ids).uniq, expires_in: ES_KEY_REDIS_TIME)
        # ReindexCustomListItemsJob.perform_later(custom_list.es_item_ids_key)

        {
          title: title,
          success_no_array: found_no_with_item_hash.keys,
          failure_no_array: no_exists_item_no_array,
          error_ae_drop_shipper_no_array: error_ae_drop_shipper_no_array
        }
      else
        {
          title: title,
          error: custom_list.errors.full_messages.join(", ")
        }
      end
    end

    # custom_list都是按拖拽商品来排序，所以不把分类的item_position作为排序条件
    def self.item_default_order
      Arel.sql("CASE WHEN items.quantity = 0 THEN 3 WHEN items.listing_type = 2 and items.start_selling_at > '#{Time.current}' THEN 2 ELSE 1 END, custom_list_items.position asc, items.position ASC, items.created_at DESC")
    end

    # instance methods
    def app_path
      { type: "productSearch", params: { customListId: id } }.to_json
    end

    def mini_program_path
      "pages/products/search/search?customListId=#{id}"
    end

    def same_day_delivery_title
      same_day_delivery ? "#{title}（当日达）" : title
    end

    def es_item_ids_key
      "custom_list_#{id}_es_item_ids"
    end

    def parent_category_name
      parent_category&.name
    end

    private

    def set_title_i18n
      self.title_zh_tw = Ropencc.conv("s2tw.json", title_zh_cn) if title_zh_tw.blank?
      self.title_en = EasyTranslate.translate(title_zh_cn, from: :"zh-CN", to: :en) if title_en.blank?
    end
  end
end
