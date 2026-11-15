# frozen_string_literal: true

class AddDeliveryTimeIdOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :delivery_time_id, :integer
    add_index :orders, :delivery_time_id

    say_with_time "Init Order delivery_time_id" do
      MagicBean::Order.reset_column_information

      MagicBean::Order.merchant_delivery.where("delivery_date >= ?", Date.current).each do |order|
        delivery_time_id = order.send(:current_delivery_area)&.delivery_time_id
        order.update_columns delivery_time_id: delivery_time_id
      end

      MagicBean::DeliveryTime.all.each do |time|
        MagicBean::Order.merchant_delivery.paid.where(delivery_time_id: time.id).where("delivery_date >= ?", Date.current).select("DISTINCT receiver_properties").group(:delivery_date).count.each do |key, value|
          order_analysis = MagicBean::DeliveryTimeOrderDateAnalysis.find_or_initialize_by(delivery_time_id: time.id, delivery_date: key.to_date)
          order_analysis.distinct_address_count = value
          order_analysis.save!
        end
      end
    end
  end
end
