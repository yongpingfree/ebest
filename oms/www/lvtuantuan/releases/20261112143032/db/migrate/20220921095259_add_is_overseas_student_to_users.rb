# frozen_string_literal: true

class AddIsOverseasStudentToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_overseas_student, :boolean, default: false
  end
end
