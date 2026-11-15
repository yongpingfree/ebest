# frozen_string_literal: true

module MagicBean
  class OverseasStudentApplication < ApplicationRecord
    include AASM

    # constants
    enum status: {
      pending: 1,
      agreed: 2,
      refused: 3,
      expired: 4
    }

    enum gender: {
      male: 1,
      female: 2
    }

    # validation macros
    validates_presence_of :email, :gender, :student_number, :school, :student_image_obverse_side
    validate :check_email

    aasm :status, column: :status, enum: true, requires_lock: true do
      state :pending, initial: true
      state :agreed
      state :refused
      state :expired

      event :agree, after_commit: [:agree_user_student_state, :enqueue_expired_student_job, :update_user_expiration_date] do
        transitions from: [:pending, :refused],
                    to: :agreed
      end

      event :refuse do
        transitions from: [:pending],
                    to: :refused
      end

      event :expire, after_commit: [:expired_user_student_state] do
        transitions from: [:agreed],
                    to: :expired
      end
    end

    # association macros
    belongs_to :user

    class << self
      def email_valid?(email)
        email =~ MagicBean::AdminUser::EMAIL_PATTERN
      end

      def student_email_valid?(email)
        email_valid?(email) && email.end_with?("edu.au")
      end
    end

    def mini_program_path

    end

    def app_path
      { type: "overseasStudentApplication" }.to_json
    end

    private
    def check_email
      errors.add(:base, I18n.t("error.overseas_student_application.invalid_format")) unless self.class.student_email_valid?(email)
    end

    def agree_user_student_state
      user.update is_overseas_student: true
    end

    def expired_user_student_state
      user.update is_overseas_student: false
    end

    # 一年后过期留学生身份
    def enqueue_expired_student_job
      ExpiredStudentJob.set(wait_until: 1.year.from_now).perform_later(id)
    end

    def update_user_expiration_date
      user.update_columns(overseas_student_expiration_date: 1.year.from_now.to_date)
    end
  end
end
