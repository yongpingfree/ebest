# frozen_string_literal: true

class CreateSignInActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :sign_in_activities do |t|
      t.string :detail_image
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :enabled, default: true, comment: "是否启用"
      t.integer :reward_integral_each_time, comment: "单次签到金币"
      t.integer :extra_reward_type, default: 1, comment: "额外奖励计算方式"
      t.integer :sign_in_times, comment: "签到次数"
      t.integer :extra_reward_integral, comment: "额外金币"
      t.timestamps
    end
  end
end
