# frozen_string_literal: true

class AddSameDayDeliveryTimeIdToDeliveryAreas < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :delivery_areas, :same_day_delivery_time
  end
end
