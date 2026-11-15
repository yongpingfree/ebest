# frozen_string_literal: true

class CreateMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :mobile
      t.datetime :birthday
      t.integer :available_integral, default: 0, comment: "可用积分"
      t.integer :blocked_integral, default: 0, comment: "冻结积分"
      t.integer :cumulative_integral, default: 0, comment: "累积获取积分"
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end

    add_index :members, :mobile, unique: true
  end
end
