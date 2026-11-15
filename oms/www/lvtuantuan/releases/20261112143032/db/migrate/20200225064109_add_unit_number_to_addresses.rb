# frozen_string_literal: true

class AddUnitNumberToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :unit_number, :string
  end
end
