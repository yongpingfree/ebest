# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.integer :buy_quota, default: 0, comment: "每个买家帐号累计限购多少件, 0表示无限制"
      t.string :title
      t.text :description
      t.string :shared_description
      t.string :no, comment: "商品货号（为商品设置的外部编号）"
      t.integer :price_in_cent, default: 0
      t.integer :origin_price_in_cent, default: 0
      t.integer :item_type, default: 1
      t.integer :quantity, comment: "总库存量"
      t.integer :listing_type, default: 1
      t.datetime :start_selling_at
      t.integer :comments_count, default: 0
      t.references :category

      t.timestamps
    end
  end
end
