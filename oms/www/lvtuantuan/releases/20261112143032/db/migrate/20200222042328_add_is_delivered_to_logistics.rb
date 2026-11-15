# frozen_string_literal: true

class AddIsDeliveredToLogistics < ActiveRecord::Migration[5.2]
  def change
    add_column :logistics, :is_delivered, :boolean, default: false
  end
end
