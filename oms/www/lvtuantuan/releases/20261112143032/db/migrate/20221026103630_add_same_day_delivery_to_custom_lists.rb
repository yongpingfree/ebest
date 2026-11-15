# frozen_string_literal: true

class AddSameDayDeliveryToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :same_day_delivery, :boolean, default: false
  end
end
