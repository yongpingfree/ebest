# frozen_string_literal: true

class CreateSignInRewardHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :sign_in_reward_histories do |t|

      t.belongs_to :sign_in_activity
      t.belongs_to :sign_in_history
      t.belongs_to :user
      t.integer :reward_type, default: 1
      t.integer :integral

      t.timestamps
    end
  end
end
