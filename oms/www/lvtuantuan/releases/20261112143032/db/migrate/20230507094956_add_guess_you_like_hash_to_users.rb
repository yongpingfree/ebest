# frozen_string_literal: true

class AddGuessYouLikeHashToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :guess_you_like_item_ids_hash, :json, default: {}, comment: "猜你喜欢的商品, 例: { \"store-1-app\": [1,2,3] }"
  end
end
