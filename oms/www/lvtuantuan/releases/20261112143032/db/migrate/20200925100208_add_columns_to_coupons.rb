# frozen_string_literal: true

class AddColumnsToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :coupons, :coupon_type, :integer, default: 1
    add_belongs_to :coupons, :invitee
  end
end
