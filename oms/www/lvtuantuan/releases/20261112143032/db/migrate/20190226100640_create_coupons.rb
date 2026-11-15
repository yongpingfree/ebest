# frozen_string_literal: true

class CreateCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :coupons do |t|
      t.string :title
      t.string :desc
      t.string :code
      t.integer :kind, default: 1
      t.datetime :expired_at
      t.datetime :start_at
      t.json :preferences, default: {}
      t.integer :status, default: 1
      t.references :coupon_template, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end
