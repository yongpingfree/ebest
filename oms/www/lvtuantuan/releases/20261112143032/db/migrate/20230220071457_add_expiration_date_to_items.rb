# frozen_string_literal: true

class AddExpirationDateToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :expiration_date, :date, comment: "产品过期日期"
  end
end
