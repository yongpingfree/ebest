# frozen_string_literal: true

class CreateOverseasStudentApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :overseas_student_applications do |t|

      t.string :nickname
      t.integer :gender
      t.date :birthday
      t.string :school
      t.string :email
      t.string :student_number
      t.string :student_image_obverse_side
      t.string :student_image_reverse_side
      t.integer :status, default: 1
      t.belongs_to :user

      t.timestamps
    end
  end
end
