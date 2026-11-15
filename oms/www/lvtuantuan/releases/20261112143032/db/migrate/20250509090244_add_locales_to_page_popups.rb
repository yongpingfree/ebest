# frozen_string_literal: true

class AddLocalesToPagePopups < ActiveRecord::Migration[5.2]
  def change
    add_column :page_popups, :locales, :string, array: true, default: ["zh-CN", "zh-TW"]
  end
end
