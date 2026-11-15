# frozen_string_literal: true

class ChangeIndexToUniqueInSignInHistories < ActiveRecord::Migration[5.2]
  def change
    remove_index :sign_in_histories, [:sign_in_activity_id, :user_id, :sign_in_date]
    add_index :sign_in_histories, [:sign_in_activity_id, :user_id, :sign_in_date], unique: true, name: "index_sign_in_histories_on_user_and_activity_and_sign_in_date"
  end
end
