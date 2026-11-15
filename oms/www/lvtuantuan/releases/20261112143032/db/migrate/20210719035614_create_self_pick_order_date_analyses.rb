# frozen_string_literal: true

class CreateSelfPickOrderDateAnalyses < ActiveRecord::Migration[5.2]
  def change
    create_table :self_pick_order_date_analyses do |t|

      t.integer :self_pick_up_id
      t.date :delivery_date
      t.integer :orders_count, default: 0

      t.timestamps
    end

    add_index :self_pick_order_date_analyses, [:delivery_date, :self_pick_up_id], unique: true, name: "self_pick_order_on_delivery_date_and_self_pick_up"

    say_with_time "Init Self Pick Order Date Analyses" do
      MagicBean::SelfPickOrderDateAnalysis.reset_column_information

      MagicBean::SelfPickUp.all.each do |self_pick|
        MagicBean::Order.self_pick.paid.where(self_pick_up_id: self_pick.id).where("delivery_date > ?", Date.current - 1.year).group(:delivery_date).count.each do |key, value|
          order_analysis = MagicBean::SelfPickOrderDateAnalysis.find_or_initialize_by(self_pick_up_id: self_pick.id, delivery_date: key.to_date)
          order_analysis.orders_count = value
          order_analysis.save!
        end
      end
    end
  end
end
