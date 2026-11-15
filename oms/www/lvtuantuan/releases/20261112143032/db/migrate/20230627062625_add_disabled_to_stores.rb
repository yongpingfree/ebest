# frozen_string_literal: true

class AddDisabledToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :disabled, :boolean, default: false, comment: "是否停用门店"
  end
end
