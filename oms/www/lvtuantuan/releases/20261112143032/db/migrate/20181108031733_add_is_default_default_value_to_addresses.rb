# frozen_string_literal: true

class AddIsDefaultDefaultValueToAddresses < ActiveRecord::Migration[5.2]
  def up
    change_column :addresses, :is_default, :boolean, default: false
  end

  def down
    change_column :addresses, :is_default, :boolean
  end
end
