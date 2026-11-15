# frozen_string_literal: true

class AddFreeShippingToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :free_shipping, :boolean, default: true, comment: "是否参与包邮计划"
  end
end
