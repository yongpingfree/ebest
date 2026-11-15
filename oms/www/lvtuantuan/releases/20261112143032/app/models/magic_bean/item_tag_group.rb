# frozen_string_literal: true

module MagicBean
  class ItemTagGroup < ApplicationRecord
    # scope
  
    # constants
  
    # attr related macros
    translates :name
    globalize_accessors attributes: [:name]
  
    # association macros
    belongs_to :item_tag_type
    has_many :item_tags, dependent: :restrict_with_error
  
    # validation macros
    validates :name_zh_cn, presence: true
    validate :name_zh_cn_uniqueness
  
    # callback
    before_create :set_name_i18n
  
    # other macros
    delegate :name, to: :item_tag_type, prefix: true

    private

    def set_name_i18n
      self.name_zh_tw = Ropencc.conv("s2tw.json", name_zh_cn) if name_zh_tw.blank?
      self.name_en = EasyTranslate.translate(name_zh_cn, from: :"zh-CN", to: :en) if name_en.blank?
    end

    def name_zh_cn_uniqueness
      if MagicBean::ItemTagGroup::Translation.where(locale: "zh-CN", name: name_zh_cn).where.not(item_tag_group_id: id).exists?
        errors.add(:name, :taken)
      end
    end
  end
end
