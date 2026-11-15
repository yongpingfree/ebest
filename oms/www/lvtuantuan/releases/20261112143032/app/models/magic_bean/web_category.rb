# frozen_string_literal: true
module MagicBean
  class WebCategory < ApplicationRecord
    # scope
    default_scope { order(position: :asc, created_at: :asc) }
    scope :top, -> { where(parent_id: nil) } # `parent` 类方法已被 Rails 占用，所以用 `top` 表示一级分类
    scope :children, -> { where.not(parent_id: nil) }
    scope :has_items, -> (store_id, channel, delivery_area, same_day_delivery = false) do
      collection = joins("LEFT JOIN items ON items.web_category_id = web_categories.id or items.minor_web_category_id = web_categories.id")
        .where(
          "items.store_id = ? AND items.channels @> ARRAY['#{channel}']::varchar[] AND (items.listing_type IN (1, 2)) AND items.gift_only = false",
          store_id
        ).distinct

      collection = collection.where("? = ANY(items.delivery_type) or ? = ANY(items.delivery_type)", "self_pick", "express") unless delivery_area

      collection = collection.where("items.item_type = ?", 3) if same_day_delivery

      collection
    end

    # constants

    # attr related macros
    enum status: {
       show: 1,
       hidden: 2
    }

    enum goto_kind: {
      sub_categories: 1, # App 二级分类
      sctt_web: 2        # SCTT 网站，doc: https://www.showdoc.com.cn/ebest/10066500567880656
    }

    ransacker :status, formatter: proc { |v| statuses[v] }
    ransack_alias :parent_category_items_info, :parent_category_items_translated_searchable_title_or_parent_category_items_sub_title_or_parent_category_items_translated_searchable_description

    translates :name
    globalize_accessors attributes: [:name]

    # association macros
    belongs_to :parent, class_name: "MagicBean::WebCategory", optional: true
    has_many :children, class_name: "MagicBean::WebCategory", foreign_key: "parent_id", dependent: :restrict_with_error
    has_many :children_on_show, -> { show }, class_name: "MagicBean::WebCategory", foreign_key: "parent_id"
    has_many :items, dependent: :restrict_with_error
    has_many :minor_items, class_name: "MagicBean::Item", foreign_key: "minor_web_category_id", dependent: :restrict_with_error
    has_many :parent_category_items, class_name: "MagicBean::Item", foreign_key: "parent_web_category_id"
    has_many :minor_category_items, class_name: "MagicBean::Item", foreign_key: "minor_web_category_id"
    has_many :on_sale_items, -> { on_sale.not_gift }, class_name: "MagicBean::Item"
    has_many :not_merchant_delivery_items, -> { on_sale.not_gift.not_merchant_delivery }, class_name: "MagicBean::Item"

    # validation macros
    validate :name_zh_cn_uniqueness, on: :create

    # callbacks
    before_validation :set_bg_color
    before_create :set_name_i18n
    before_save :set_child_attributes
    after_commit :update_children_attributes, unless: :parent_id
    after_commit :update_items_position, if: -> { parent_id? && saved_change_to_sort_item_ids? }

    # other macros

    def mini_program_path
      parent_id ? "pages/tabbar/category/category?pid=#{parent_id}&cid=#{id}" : "pages/tabbar/category/category?pid=#{id}"
    end

    def app_path
      params = parent_id ? { pid: parent_id, p_name: parent.name_en, cid: id } : { pid: id, p_name: name_en }
      { type: "webCategory", params: params }.to_json
    end

    def set_bg_color
      self.bg_color = bg_color || parent&.bg_color || "#FEEDDC"
    end

    def sort_items
      sort_item_ids.present? ? items.where(id: sort_item_ids).reorder_by_ids(sort_item_ids) : []
    end

    def es_item_ids_key
      "web_category_#{id}_es_item_ids"
    end

    private

    def set_name_i18n
      self.name_zh_tw = Ropencc.conv("s2tw.json", name_zh_cn) if name_zh_tw.blank?
      self.name_en = EasyTranslate.translate(name_zh_cn, from: :"zh-CN", to: :en) if name_en.blank?
    end

    def set_child_attributes
      return if parent.nil?

      self.can_create_invoice = parent.can_create_invoice
      self.need_age_verification = parent.need_age_verification
    end

    def update_children_attributes
      children.update_all(can_create_invoice: can_create_invoice, need_age_verification: need_age_verification)
    end

    def update_items_position
      sort_items.each_with_index do |item, index|
        item.update_columns(position: index)
      end

      items.where.not(id: sort_item_ids).update_all(position: Item::MAX_POSITION)

      # 修改了分类商品排序，需要更新ES数据
      # if items.present?
      #   Rails.cache.write(es_item_ids_key, items.ids, expires_in: MagicBean::CustomList::ES_KEY_REDIS_TIME)
      #   ReindexCustomListItemsJob.perform_later(es_item_ids_key)
      # end
    end

    def name_zh_cn_uniqueness
      if MagicBean::WebCategory::Translation.where(locale: "zh-CN", name: name_zh_cn).where.not(web_category_id: id).exists?
        errors.add(:name, :taken)
      end
    end
  end
end
