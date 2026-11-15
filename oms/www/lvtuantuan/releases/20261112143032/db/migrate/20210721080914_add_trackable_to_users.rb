# frozen_string_literal: true

class AddTrackableToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :current_visit_ip, :string
    add_column :users, :last_visit_ip, :string
    add_column :users, :current_visit_at, :datetime
    add_column :users, :last_visit_at, :datetime
  end
end
