# frozen_string_literal: true

module BeansApp::API::Entities
  class OverseasStudentApplication < ::CommonEntities::Model
    expose :nickname
    expose :user_id
    expose :gender
    expose :birthday
    expose :school
    expose :email
    expose :student_number
    expose :student_image_obverse_side
    expose :student_image_reverse_side
    expose :status
  end
end
