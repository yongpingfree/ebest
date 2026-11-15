# frozen_string_literal: true

class CreateUserRecommendedProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :user_recommended_products do |t|
      t.belongs_to :user
      t.string :mobile, comment: "手机号"
      t.text :recommended_products, comment: "推荐的商品"
      t.string :wechat, comment: "微信号"
      t.string :images, default: [], array: true

      t.timestamps
    end
  end
end
