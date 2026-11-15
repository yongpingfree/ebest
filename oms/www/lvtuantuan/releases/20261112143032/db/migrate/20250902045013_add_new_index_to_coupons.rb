# frozen_string_literal: true

class AddNewIndexToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_index :coupons, [:coupon_template_id, :status], name: "index_coupons_on_coupon_template_id_and_status"
  end
end
