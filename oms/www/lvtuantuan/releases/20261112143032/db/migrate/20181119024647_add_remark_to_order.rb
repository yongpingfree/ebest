# frozen_string_literal: true

class AddRemarkToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :remark, :text, comment: "卖家备注"
  end
end
