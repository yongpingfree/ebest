# frozen_string_literal: true

class MembersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def email_confirmation
    @member = params[:token].present? ? MagicBean::Member.find_by(email_confirmation_token: params[:token]) : nil

    @member.touch(:email_verified_at) if @member && !@member.email_confirmed?
  end
end
