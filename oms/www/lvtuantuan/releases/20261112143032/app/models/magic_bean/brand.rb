# frozen_string_literal: true
module MagicBean
  class Brand < ApplicationRecord
    include ResourceUrlValidationConcern
    # scope

    # constants
    RESOURCE_URL_COLUMNS = [:cover]

    # attr related macros
    translates :name
    globalize_accessors attributes: [:name]

    # association macros
    has_many :items, dependent: :restrict_with_error

    # validation macros
    validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validate :name_zh_cn_uniqueness

    # callbacks
    before_create :set_name_i18n
    after_commit :enqueue_generate_aws_lambda_image_job, if: -> { cover_previously_changed? }

    # other macros
    ransack_alias :items_info, :items_translated_searchable_title_or_items_sub_title_or_items_translated_searchable_description

    def mini_program_path
      "/pages/products/search/search"
    end

    def app_path
      { type: "productSearch", params: { brand_id_in: self.id.to_s } }.to_json
    end

    private

    def set_name_i18n
      self.name_zh_tw = Ropencc.conv("s2tw.json", name_zh_cn) if name_zh_tw.blank?
      self.name_en = EasyTranslate.translate(name_zh_cn, from: :"zh-CN", to: :en) if name_en.blank?
    end

    def name_zh_cn_uniqueness
      if MagicBean::Brand::Translation.where(locale: "zh-CN", name: name_zh_cn).where.not(brand_id: id).exists?
        errors.add(:name, :taken)
      end
    end

    def enqueue_generate_aws_lambda_image_job
      GenerateAwsLambdaImageJob.perform_later(self.class.name, id)
    end
  end
end
