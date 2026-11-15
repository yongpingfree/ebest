# frozen_string_literal: true

class ChangeDeliveryTypeToArrayToItems < ActiveRecord::Migration[5.2]
  def change
    remove_column :items, :delivery_type, :integer, default: 1
    add_column :items, :delivery_type, :string, array: true, default: []
  end
end
