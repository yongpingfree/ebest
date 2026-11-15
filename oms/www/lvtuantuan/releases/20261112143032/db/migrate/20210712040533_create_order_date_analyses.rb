# frozen_string_literal: true

class CreateOrderDateAnalyses < ActiveRecord::Migration[5.2]
  def change
    create_table :order_date_analyses do |t|

      t.date :delivery_date
      t.integer :store_id
      t.integer :distinct_address_count, default: 0
      t.timestamps
    end

    add_index :order_date_analyses, [:delivery_date, :store_id], unique: true

    say_with_time "Init Merchant Order Date Analyses" do
      MagicBean::OrderDateAnalysis.reset_column_information

      MagicBean::Store.all.each do |store|
        MagicBean::Order.merchant_delivery.paid.where(mark_for_orders_limit: true, store_id: store.id).where("delivery_date > ?", Date.current - 1.year).select("DISTINCT receiver_properties").group(:delivery_date).count.each do |key, value|
          order_analysis = MagicBean::OrderDateAnalysis.find_or_initialize_by(store_id: store.id, delivery_date: key.to_date)
          order_analysis.distinct_address_count = value
          order_analysis.save!
        end
      end
    end
  end
end
