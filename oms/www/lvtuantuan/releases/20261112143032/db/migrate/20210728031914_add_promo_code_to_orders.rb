# frozen_string_literal: true

class AddPromoCodeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :promo_code, foreign_key: true

    say_with_time "init_used_promo_codes" do
      MagicBean::PromoCode.where.not(order_id: nil).pluck(:id, :order_id).each do |promo_code_id, order_id|
        # TODO: 后面删除 promo_codes 表上的 order_id 字段
        MagicBean::Order.find(order_id).update_attribute(:promo_code_id, promo_code_id)
      end
    end
  end
end
