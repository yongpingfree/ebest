# frozen_string_literal: true

class CreateAuctionActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :auction_activities do |t|
      t.string :cover, null: false
      t.datetime :start_at, null: false
      t.datetime :default_end_at, null: false
      t.boolean :auto_renewal_end_at, null: false, default: false
      t.datetime :final_end_at
      t.datetime :publish_at
      t.integer :state, null: false, default: 0
      t.integer :starting_price_in_cent, null: false, comment: "起拍价"
      t.integer :bidding_increments_in_cent, null: false, comment: "出价最小增额"
      t.integer :reserve_price_in_cent, comment: "底价"
      t.integer :directly_purchase_price_in_cent, comment: "直接购买价"
      t.string :detail_images, array: true, default: [], comment: "主图"
      t.string :main_images, array: true, default: [], comment: "详情图"
      t.references :category
      t.references :parent_category
      t.references :minor_category
      t.references :minor_parent_category

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MagicBean::Auction::Activity.create_translation_table! title: :string, description: :string
      end

      dir.down do
        MagicBean::Auction::Activity.drop_translation_table!
      end
    end
  end
end
