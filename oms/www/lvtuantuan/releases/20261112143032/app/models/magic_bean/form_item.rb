# frozen_string_literal: true

module MagicBean
  class FormItem < ApplicationRecord
    # scope
    scope :app_channel, -> { where("channels @> ARRAY['app']::varchar[]") }
    scope :mini_program_channel, -> { where("channels @> ARRAY['mini_program']::varchar[]") }
    scope :web_channel, -> { where("channels @> ARRAY['web']::varchar[]") }

    # attr related macros
    translates :title, :description, :name_placeholder, :mobile_placeholder, :email_placeholder, :birthday_placeholder, :address_placeholder, :remark_placeholder
    globalize_accessors attributes: [:title, :description, :name_placeholder, :mobile_placeholder, :email_placeholder, :birthday_placeholder, :address_placeholder, :remark_placeholder]
    alias_attribute :name, :title

    enum listing_type: {
      online: 1,
      pending: 2
    }

    # association macros
    belongs_to :category
    belongs_to :parent_category, optional: true, class_name: "MagicBean::Category", foreign_key: "parent_category_id"
    belongs_to :minor_category, optional: true, class_name: "MagicBean::Category", foreign_key: "minor_category_id"
    belongs_to :store
    has_many :form_item_applications, dependent: :restrict_with_error

    # validation macros
    validates :title_zh_cn, :description_zh_cn, :main_images, :detail_images, :cover, presence: true

    # callbacks
    before_create :set_i18n_attributes
    before_save :set_parent_category, :translate_fields_with_zh_tw, :set_translated_searchable_attrs
    validate :check_category_id, :check_channels, :check_form_options

    # other macros
    delegate :name, to: :category, prefix: true, allow_nil: true
    delegate :name, to: :parent_category, prefix: true, allow_nil: true
    delegate :name, to: :minor_category, prefix: true, allow_nil: true
    delegate :name, to: :store, prefix: true

    def channels_text
      channels.map do |channel|
        I18n.t("grape.channels.#{channel}")
      end.join("/")
    end

    def channel_match?(current_channel)
      self.channels.include?(current_channel)
    end

    # 此方法为匹配数组中全部元素
    def self.channels_contains(item_channels = [])
      channels_str = item_channels.map { |channel| "\'#{channel}\'" }.join(",")
      where(Arel.sql("channels @> ARRAY[#{channels_str}]::varchar[]"))
    end

    def destroyable?
      !MagicBean::FormItemApplication.exists?(form_item_id: id)
    end

    def app_path
      { type: "formItemDetail", params: { id: id } }.to_json
    end

    def mini_program_path; end

    private

    def check_category_id
      errors.add(:base, "不能直接绑定一级分类") if category && category.parent_id.nil?
    end

    def check_channels
      errors.add(:base, "平台限制不能为空") if channels.blank?
    end

    def check_form_options
      errors.add(:base, "表格栏位至少选择一项") if form_options.blank?
    end

    def set_parent_category
      self.parent_category_id = category.parent_id if category.present? || category_id_changed?
    end

    def set_translated_searchable_attrs
      self.translated_searchable_title = [title_zh_cn, title_zh_tw, title_en].compact.join(" ")
      self.translated_searchable_description = [description_zh_cn, description_zh_tw, description_en].compact.join(" ")
    end

    def set_i18n_attributes
      %w[title description].each do |attr|
        text_zh_cn = send("#{attr}_zh_cn")
        if text_zh_cn.present?
          self.send("#{attr}_zh_tw=", Ropencc.conv("s2tw.json", text_zh_cn)) if send("#{attr}_zh_tw").blank?
          self.send("#{attr}_en=", EasyTranslate.translate(text_zh_cn, from: :"zh-CN", to: :en)) if send("#{attr}_en").blank?
        end
      end
    end

    def translate_fields_with_zh_tw
      changed_keys = changes.keys

      %w[title description].each do |attr|
        next if changed_keys.include?("#{attr}_zh_tw")

        text_zh_cn = send("#{attr}_zh_cn")
        if text_zh_cn.present? && send("#{attr}_changed?")
          self.send("#{attr}_zh_tw=", Ropencc.conv("s2tw.json", text_zh_cn))
        end
      end
    end
  end
end
