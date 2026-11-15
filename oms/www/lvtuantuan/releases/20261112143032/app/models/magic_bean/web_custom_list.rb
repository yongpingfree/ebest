# frozen_string_literal: true

module MagicBean
  class WebCustomList < ApplicationRecord
    # scope

    # constants
    REDIS_API_KEY_NAMESPACE = "app_api_web_custom_list/"
    ES_KEY_REDIS_TIME = 100.minutes

    # attr related macros
    translates :title
    globalize_accessors attributes: [:title]

    enum page_location: {
      homepage_head: 1, # 首页头部导航栏
      homepage_body: 2 # 首页主体位置
    }
    ransacker :page_location, formatter: proc { |val| page_locations[val] }
    enum orientation: {
      horizontal: 1, # 横向
      vertical: 2 # 竖向
    }

    # association macros
    belongs_to :store
    has_many :web_custom_list_items, dependent: :destroy, inverse_of: :web_custom_list
    has_many :items, -> { includes(:web_custom_list_items).reorder("web_custom_list_items.position ASC") }, through: :web_custom_list_items, source: :item

    # validation macros
    validates :title_en, presence: true

    # callbacks
    after_commit :clear_all_redis_keys

    # other macros
    accepts_nested_attributes_for :web_custom_list_items, allow_destroy: true

    delegate :name, to: :store, prefix: true

    # class methods
    def self.import_from_excel(title, file_url, admin_user_id, store_id, list_id)
      xlsx = Roo::Spreadsheet.open file_url
      sheet = xlsx.sheet 0
      no_exists_item_no_array = []
      found_no_array = []
      found_items = {} # key: item id, value: position
      es_item_ids = []

      index = 1
      sheet.each_row_streaming(offset: 1) do |row|
        next if row[0].blank?
        no = row[0].value.to_s.strip

        break if no.blank?
        item = MagicBean::Item.find_by(no: no, store_id: store_id)

        if item.present?
          found_no_array << no
          found_items[item.id] = index
          es_item_ids << item.id
          index += 1
        else
          no_exists_item_no_array << no
        end
      end

      web_custom_list_items_attributes = []
      found_items.each_pair do |item_id, position|
        web_custom_list_items_attributes << { item_id: item_id, position: position }
      end

      custom_list = MagicBean::WebCustomList.find_by id: list_id
      if custom_list.nil?
        custom_list = MagicBean::WebCustomList.new(
          title_zh_cn: title, title_zh_tw: title, title_en: title,
          store_id: store_id, web_custom_list_items_attributes: web_custom_list_items_attributes
        )
      else
        old_item_ids = custom_list.item_ids
        es_item_ids = (old_item_ids + es_item_ids) - (old_item_ids & es_item_ids)

        # 已存在的商品列表，先删除所有商品，再重新导入
        custom_list.web_custom_list_items.delete_all
        custom_list.web_custom_list_items_attributes = web_custom_list_items_attributes
      end

      if custom_list.save
        # Rails.cache.write(custom_list.es_item_ids_key, ((Rails.cache.fetch(custom_list.es_item_ids_key) || []) + es_item_ids).uniq, expires_in: ES_KEY_REDIS_TIME)
        # ReindexCustomListItemsJob.perform_later(custom_list.es_item_ids_key)

        {
          title: title,
          success_no_array: found_no_array,
          failure_no_array: no_exists_item_no_array
        }
      else
        {
          title: title,
          error: custom_list.errors.full_messages.join(", ")
        }
      end
    end

    def clear_all_redis_keys
      Redis::Objects.redis.keys("#{REDIS_API_KEY_NAMESPACE}*").each do |key|
        Redis::Value.new(key).clear
      end
    end

    # instance methods

    # 为了跟已有跳转字段兼容，使用 `app_path` 名称，但只用于网页端跳转
    def app_path
      { type: "webCustomList", params: { id: id } }.to_json
    end

    def es_item_ids_key
      "web_custom_list_#{id}_es_item_ids"
    end
  end
end
