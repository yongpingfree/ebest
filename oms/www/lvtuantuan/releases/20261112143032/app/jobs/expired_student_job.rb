# frozen_string_literal: true

class ExpiredStudentJob < ApplicationJob
  queue_as :default

  def perform(id)
    application = MagicBean::OverseasStudentApplication.find_by(id: id)
    application.expire! if application && application.agreed?
  end
end
