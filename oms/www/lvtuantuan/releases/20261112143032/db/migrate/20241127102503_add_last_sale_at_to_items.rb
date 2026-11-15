# frozen_string_literal: true

class AddLastSaleAtToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :last_sale_at, :datetime, comment: "最近一次开卖时间"
    add_column :items, :last_offline_at, :datetime, comment: "最近一次下架时间"

    say_with_time "initialize last_offline_at" do
      MagicBean::Item.reset_column_information

      # 将所有下架且first_sale_at为空的商品的last_offline_at设置为updated_at
      MagicBean::Item.pending.where(first_sale_at: nil).update_all("last_offline_at = updated_at")
    end
  end
end
