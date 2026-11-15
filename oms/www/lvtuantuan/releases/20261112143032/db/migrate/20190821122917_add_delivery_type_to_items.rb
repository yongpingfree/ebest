# frozen_string_literal: true

class AddDeliveryTypeToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :delivery_type, :integer, default: 1
  end
end
