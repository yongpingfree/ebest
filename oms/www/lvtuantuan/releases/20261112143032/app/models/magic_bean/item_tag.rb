# frozen_string_literal: true

module MagicBean
  class ItemTag < ApplicationRecord
    include ItemTagsImportConcern

    # scope

    # constants

    # attr related macros
    translates :name
    globalize_accessors attributes: [:name]
  
    # association macros
    belongs_to :item_tag_group
    has_many :item_tag_relations, dependent: :destroy
  
    # validation macros
    validates :name_zh_cn, presence: true
    validate :name_zh_cn_uniqueness
  
    # callback
    before_create :set_name_i18n
  
    # other macros
    delegate :name, to: :item_tag_group, prefix: true
    delegate :item_tag_type_name, to: :item_tag_group

    def recalculate_tag_count
      update_columns(item_tag_relations_count: item_tag_relations.size)
    end

    private

    def set_name_i18n
      self.name_zh_tw = Ropencc.conv("s2tw.json", name_zh_cn) if name_zh_tw.blank?
      self.name_en = EasyTranslate.translate(name_zh_cn, from: :"zh-CN", to: :en) if name_en.blank?
    end

    # 同个标签组下标签名称不能重复
    def name_zh_cn_uniqueness
      if MagicBean::ItemTag::Translation.where(locale: "zh-CN", name: name_zh_cn, item_tag_id: MagicBean::ItemTag.where(item_tag_group_id: item_tag_group_id).select(:id)).where.not(item_tag_id: id).exists?
        errors.add(:name, :taken)
      end
    end
  end
end
