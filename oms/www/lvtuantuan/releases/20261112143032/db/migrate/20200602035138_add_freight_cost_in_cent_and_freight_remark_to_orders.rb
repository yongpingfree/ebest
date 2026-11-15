# frozen_string_literal: true

class AddFreightCostInCentAndFreightRemarkToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :freight_cost_in_cent, :integer, default: 0, comment: "订单运费成本"
    add_column :orders, :freight_remark, :string, comment: "订单运费备注"

    say_with_time "update order freight_cost_in_cent" do
      MagicBean::Order.reset_column_information

      MagicBean::Order.find_each do |order|
        # 计算不同商品的运费最大值，使用其作为总运费
        total_weight_in_gram = order.order_items.sum(0) { |item| item.weight_in_gram * item.quantity }

        _, order.freight_cost_in_cent  = order.order_items.map(&:item).uniq.map do |item|
          item.calculate_freight(total_weight_in_gram, order.receiver_postal_code, order.receiver_city_name, order.delivery_type)
        end.max

        order.save(validate: false)
      end
    end
  end
end
