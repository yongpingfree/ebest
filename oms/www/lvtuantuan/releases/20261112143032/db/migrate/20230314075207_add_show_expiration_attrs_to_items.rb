# frozen_string_literal: true

class AddShowExpirationAttrsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :show_expiration_date, :boolean, default: false
    add_column :items, :days_ahead_to_show_expiration, :integer
  end
end
