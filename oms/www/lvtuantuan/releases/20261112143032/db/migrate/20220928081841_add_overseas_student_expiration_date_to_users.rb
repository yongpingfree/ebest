# frozen_string_literal: true

class AddOverseasStudentExpirationDateToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :overseas_student_expiration_date, :date
  end
end
