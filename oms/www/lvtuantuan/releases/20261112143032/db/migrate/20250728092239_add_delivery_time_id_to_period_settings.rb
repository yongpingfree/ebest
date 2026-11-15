# frozen_string_literal: true

class AddDeliveryTimeIdToPeriodSettings < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :delivery_time_period_settings, :delivery_time
  end
end
