# frozen_string_literal: true

class AddSellerReplyToAfterSale < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :seller_reply, :string
  end
end
