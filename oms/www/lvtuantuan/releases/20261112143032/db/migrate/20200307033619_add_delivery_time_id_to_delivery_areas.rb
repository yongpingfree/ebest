# frozen_string_literal: true

class AddDeliveryTimeIdToDeliveryAreas < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :delivery_areas, :delivery_time
  end
end
