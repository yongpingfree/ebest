# frozen_string_literal: true

class AddDeliveryWeekdaysToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :delivery_weekdays, :string, array: true, default: []
  end
end
