# frozen_string_literal: true

class RemoveSupportExpressFromGiftActivities < ActiveRecord::Migration[5.2]
  def change
    remove_column :gift_activities, :support_express, :boolean, default: true
  end
end
