# frozen_string_literal: true

class AddSameDayDeliveryToSelfPickUps < ActiveRecord::Migration[5.2]
  def change
    add_column :self_pick_ups, :same_day_delivery, :boolean, default: false
  end
end
