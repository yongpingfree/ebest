# frozen_string_literal: true

class AddFreightCostToFreightTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :freight_templates, :first_kg_cost_in_cent, :integer, default: 0, comment: "1KG以内运费成本"
    add_column :freight_templates, :second_kg_cost_in_cent, :integer, default: 0, comment: "2KG以内运费成本"
    add_column :freight_templates, :continued_weight_cost_in_cent, :integer, default: 0, comment: "超过2KG后每KG运费成本，不足1KG按1KG算"
    add_column :freight_templates, :extra_cost_in_cent, :integer, default: 0, comment: "超过2KG后一次性的额外费用"

    say_with_time "update freight cost" do
      MagicBean::FreightTemplate.reset_column_information

      MagicBean::FreightTemplate.find_each do |template|
        template.first_kg_cost_in_cent = template.first_kg_charge_in_cent
        template.second_kg_cost_in_cent = template.second_kg_charge_in_cent
        template.continued_weight_cost_in_cent = template.continued_weight_charge_in_cent
        template.extra_cost_in_cent = template.extra_charge_in_cent
        template.save(validate: false)
      end
    end
  end
end
