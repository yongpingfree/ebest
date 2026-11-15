# frozen_string_literal: true
module MagicBean
  class FreightTemplate < ApplicationRecord
    include PriceConvertConcern

    translates :name
    globalize_accessors attributes: [:name]

    convert_price_to_yuan :first_kg_charge_in_cent, :second_kg_charge_in_cent, :continued_weight_charge_in_cent, :extra_charge_in_cent,
      :free_shipping_amount_in_cent, :app_free_shipping_amount_in_cent, :mini_program_free_shipping_amount_in_cent, :web_free_shipping_amount_in_cent,
      :first_kg_cost_in_cent, :second_kg_cost_in_cent, :continued_weight_cost_in_cent, :extra_cost_in_cent, :long_distance_fee_in_cent

    validates :first_kg_charge_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :second_kg_charge_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :continued_weight_charge_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :extra_charge_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :free_shipping_amount_in_cent, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
    validates :app_free_shipping_amount_in_cent, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
    validates :mini_program_free_shipping_amount_in_cent, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
    validates :web_free_shipping_amount_in_cent, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

    validates :first_kg_cost_in_cent, :second_kg_cost_in_cent, :continued_weight_cost_in_cent, :extra_cost_in_cent, presence: true, numericality: { greater_than_or_equal_to: 0 }

    enum delivery_type: { merchant_delivery: 1, express: 2, self_pick: 3 }

    ransacker :delivery_type, formatter: proc { |v| delivery_types[v] }

    has_and_belongs_to_many :items
    has_many :au_suburb_freight_templates, inverse_of: :freight_template, dependent: :destroy
    has_many :au_suburbs, through: :au_suburb_freight_templates
    belongs_to :store
  end
end
