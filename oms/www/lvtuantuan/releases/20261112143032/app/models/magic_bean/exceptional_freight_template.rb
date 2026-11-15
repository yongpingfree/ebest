# frozen_string_literal: true
module MagicBean
  class ExceptionalFreightTemplate < FreightTemplate
    # association macros
    belongs_to :default_freight_template, foreign_key: "freight_template_id", inverse_of: :exceptional_freight_templates

    # validation macros
    validates :au_suburb_freight_templates, length: { minimum: 1, too_short: "不能少于#{count}个" }
    # callbacks
    before_validation :set_store_id

    # other macros

    def set_store_id
      self.store_id = default_freight_template.store_id
    end
  end
end
