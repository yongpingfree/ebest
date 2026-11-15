# frozen_string_literal: true

class AddHousingTypeToAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :addresses, :housing_type, :integer
  end
end
