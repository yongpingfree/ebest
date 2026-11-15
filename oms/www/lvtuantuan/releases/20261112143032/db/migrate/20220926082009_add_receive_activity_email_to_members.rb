# frozen_string_literal: true

class AddReceiveActivityEmailToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :receive_activity_email, :boolean, default: false
  end
end
