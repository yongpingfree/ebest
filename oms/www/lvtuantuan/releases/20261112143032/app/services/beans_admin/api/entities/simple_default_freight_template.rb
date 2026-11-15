# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleDefaultFreightTemplate < ::CommonEntities::Model
    translate_expose :name, documentation: { desc: "模版名称" }
    expose :delivery_type, documentation: { desc: "配送类型" }
    expose :first_kg_charge_in_cent
    expose :second_kg_charge_in_cent
    expose :continued_weight_charge_in_cent
    expose :extra_charge_in_cent
    expose :free_shipping_amount_in_cent
    expose :app_free_shipping_amount_in_cent
    expose :mini_program_free_shipping_amount_in_cent
    expose :web_free_shipping_amount_in_cent
    expose :long_distance_fee_in_cent
    expose :ae_drop_shipper
    float_expose :first_kg_charge_in_yuan, documentation: { type: Float, desc: "1KG以内运费" }
    float_expose :second_kg_charge_in_yuan, documentation: { type: Float, desc: "2KG以内运费" }
    float_expose :continued_weight_charge_in_yuan, documentation: { type: Float, desc: "超过2KG后每KG运费，不足1KG按1KG算" }
    float_expose :extra_charge_in_yuan, documentation: { type: Float, desc: "超过2KG后一次性的额外费用" }
    float_expose :free_shipping_amount_in_yuan, documentation: { type: Float, desc: "满X金额免运费" }
    float_expose :app_free_shipping_amount_in_yuan, documentation: { type: Float, desc: "App满X金额免运费" }
    float_expose :mini_program_free_shipping_amount_in_yuan, documentation: { type: Float, desc: "小程序满X金额免运费" }
    float_expose :web_free_shipping_amount_in_yuan, documentation: { type: Float, desc: "Web满X金额免运费" }
    float_expose :first_kg_cost_in_yuan, documentation: { type: Float, desc: "1KG以内运费成本" }
    float_expose :second_kg_cost_in_yuan, documentation: { type: Float, desc: "2KG以内运费成本" }
    float_expose :continued_weight_cost_in_yuan, documentation: { type: Float, desc: "超过2KG后每KG运费成本，不足1KG按1KG算" }
    float_expose :extra_cost_in_yuan, documentation: { type: Float, desc: "超过2KG后一次性的额外费用成本" }
    float_expose :long_distance_fee_in_yuan, documentation: { type: Float, desc: "远程运费" }
  end
end
