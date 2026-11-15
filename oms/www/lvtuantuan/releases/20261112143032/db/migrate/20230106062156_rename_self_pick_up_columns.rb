# frozen_string_literal: true

class RenameSelfPickUpColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :self_pick_ups, :same_day_delivery, :support_same_day_delivery
  end
end
