# frozen_string_literal: true

class AddNoToPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :no, :string
  end
end
