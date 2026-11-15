# frozen_string_literal: true

class AddSupportExpressToGiftActicities < ActiveRecord::Migration[5.2]
  def change
    add_column :gift_activities, :support_express, :boolean, default: true
  end
end
