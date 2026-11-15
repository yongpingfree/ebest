# frozen_string_literal: true

class CreateAuctionActivityParticipations < ActiveRecord::Migration[5.2]
  def change
    create_table :auction_activity_participations do |t|
      t.references :user, foreign_key: true
      t.references :auction_activity, foreign_key: true
      t.integer :state, null: false, default: 2  # 拍卖活动 bidding 状态为 2，这里跟随该值
      t.references :auction_order, foreign_key: { to_table: :orders }
      t.references :store, foreign_key: true
      t.integer :amount_in_cent

      t.timestamps
    end

    add_index :auction_activity_participations, [:user_id, :auction_activity_id], unique: true, name: "index_activity_participations_on_user_id_and_activity_id"
  end
end
