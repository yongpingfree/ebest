# frozen_string_literal: true

class AddEnabledToSelfPickUps < ActiveRecord::Migration[5.2]
  def change
    add_column :self_pick_ups, :enabled, :boolean, default: true
  end
end
