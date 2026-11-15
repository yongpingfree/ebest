# frozen_string_literal: true

class AddCountAttrsToPromoCodes < ActiveRecord::Migration[5.2]
  def change
    add_column :promo_codes, :total_avaliable_count, :integer, default: 1, null: false
    add_column :promo_codes, :used_count, :integer, default: 0, null: false

    say_with_time "init_used_count_of_promo_codes" do
      MagicBean::Order.where.not(promo_code_id: nil).find_each do |order|
        order.promo_code.increment! :used_count
      end
    end
  end
end
