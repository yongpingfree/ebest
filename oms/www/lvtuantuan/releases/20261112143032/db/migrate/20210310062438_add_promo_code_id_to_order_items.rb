# frozen_string_literal: true

class AddPromoCodeIdToOrderItems < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :order_items, :promo_code
  end
end
