# frozen_string_literal: true
module MagicBean
  class SkuValue < ApplicationRecord
    # scope

    # constants

    # attr related macros

    # association macros
    belongs_to :sku_property

    # validation macros
    validates_uniqueness_of :text, scope: [:sku_property_id, :ae_property_value_id]

    # callbacks
    before_create :set_i18n_text

    # other macros
    translates :text
    globalize_accessors attributes: [:text]

    private

    def set_i18n_text
      if text_zh_cn.present?
        self.text_zh_tw ||= Ropencc.conv("s2tw.json", text_zh_cn)
        self.text_en ||= EasyTranslate.translate(text_zh_cn, from: :"zh-CN", to: :en)
      end
    end
  end
end
