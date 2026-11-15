# frozen_string_literal: true

class AddNotEligibleForFreeGiftToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :not_eligible_for_free_gift, :boolean, default: false, comment: "商品是否不参与满赠"
    add_column :order_items, :not_eligible_for_free_gift, :boolean, default: false, comment: "商品是否不参与满赠"
  end
end
