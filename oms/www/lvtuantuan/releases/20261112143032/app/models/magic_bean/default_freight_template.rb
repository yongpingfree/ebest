# frozen_string_literal: true
module MagicBean
  class DefaultFreightTemplate < FreightTemplate
    # constants

    # attr related macros

    # association macros
    has_many :exceptional_freight_templates, foreign_key: "freight_template_id", class_name: "MagicBean::ExceptionalFreightTemplate", dependent: :destroy, inverse_of: :default_freight_template

    # validation macros
    validates :name, presence: true
    # 每个delivery_type只允许创建一个default_freight_template
    validate :check_template_uniqueness

    # callbacks

    # other macros
    accepts_nested_attributes_for :exceptional_freight_templates, allow_destroy: true

    def calculate_freight(weight_in_gram, postal_code, city_name, exceptional_template = nil)

      tmpl = exceptional_template || exceptional_freight_templates.ransack(au_suburbs_postal_code_eq: postal_code, au_suburbs_name_case_insensitive_eq: city_name&.downcase).result.distinct.first if postal_code || city_name
      tmpl = self if tmpl.nil?

      weight_in_kg = weight_in_gram / 1000.0

      if weight_in_kg <= 1 # 1KG以内运费
        [tmpl.first_kg_charge_in_cent, tmpl.first_kg_cost_in_cent, tmpl.long_distance_fee_in_cent]
      elsif weight_in_kg <= 2 # 2KG以内运费
        [tmpl.second_kg_charge_in_cent, tmpl.second_kg_cost_in_cent, tmpl.long_distance_fee_in_cent]
      else # 超过2KG后续重运费，不足1KG按1KG算
        [
          tmpl.second_kg_charge_in_cent + (weight_in_kg - 2).ceil * tmpl.continued_weight_charge_in_cent + tmpl.extra_charge_in_cent,
          tmpl.second_kg_cost_in_cent + (weight_in_kg - 2).ceil * tmpl.continued_weight_cost_in_cent + tmpl.extra_cost_in_cent,
          tmpl.long_distance_fee_in_cent
        ]
      end
    end

    private
    def check_template_uniqueness
      errors.add(:base, "一个发货方式只能创建一个运费模板") if self.class.where(delivery_type: delivery_type, store_id: store_id, ae_drop_shipper: ae_drop_shipper).where.not(id: id).exists?
    end
  end
end
