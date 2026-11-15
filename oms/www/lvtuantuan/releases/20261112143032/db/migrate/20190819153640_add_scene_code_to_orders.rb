# frozen_string_literal: true

class AddSceneCodeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :scene_code, :string
  end
end
