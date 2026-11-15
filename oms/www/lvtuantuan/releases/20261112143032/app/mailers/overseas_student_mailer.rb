# frozen_string_literal: true

class OverseasStudentMailer < ApplicationMailer
  def notify(email, message, subject)
    noreplys_smtp = Rails.application.credentials[Rails.env.to_sym][:noreplys_smtp]
    delivery_options = {
      user_name: noreplys_smtp[:user_name],
      password: noreplys_smtp[:password],
      address: noreplys_smtp[:address]
    }

    @message = message
    @subject = subject

    if email.present?
      mail(
        from: noreplys_smtp[:user_name],
        to: email,
        subject: @subject,
        delivery_method_options: delivery_options
      )
    end
  end
end
