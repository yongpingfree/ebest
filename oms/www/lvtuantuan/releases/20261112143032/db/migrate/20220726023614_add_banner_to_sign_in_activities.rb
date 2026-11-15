# frozen_string_literal: true

class AddBannerToSignInActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :sign_in_activities, :banner, :string
  end
end
