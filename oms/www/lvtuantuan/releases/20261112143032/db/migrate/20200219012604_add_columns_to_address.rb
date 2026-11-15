# frozen_string_literal: true

class AddColumnsToAddress < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :email, :string
    add_column :addresses, :street, :string
    add_column :addresses, :street_number, :string
    add_column :addresses, :company_name, :string
    add_column :addresses, :alias_name, :string, comment: "地址信息名称"
  end
end
