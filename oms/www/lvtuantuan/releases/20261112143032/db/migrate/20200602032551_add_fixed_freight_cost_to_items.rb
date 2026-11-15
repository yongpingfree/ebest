# frozen_string_literal: true

class AddFixedFreightCostToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :fixed_freight_cost, :integer, default: 0, comment: "固定运费成本"

    say_with_time "update freight cost" do
      MagicBean::Item.reset_column_information

      MagicBean::Item.find_each do |item|
        next unless item.freight_fixed?
        item.fixed_freight_cost = item.fixed_freight
        item.save(validate: false)
      end
    end
  end
end
