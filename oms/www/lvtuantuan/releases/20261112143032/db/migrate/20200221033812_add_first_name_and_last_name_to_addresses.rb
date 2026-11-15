# frozen_string_literal: true

class AddFirstNameAndLastNameToAddresses < ActiveRecord::Migration[5.2]
  def change
    rename_column :addresses, :receiver_name, :first_name
    add_column :addresses, :last_name, :string
  end
end
