# frozen_string_literal: true

class AddRemarkToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :remark, :string, comment: "备注"
  end
end
