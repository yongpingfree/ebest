# frozen_string_literal: true

class AddNewUserPriceInCentToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :new_user_price_in_cent, :integer
  end
end
