# frozen_string_literal: true

class CommwebPaymentsController  < ApplicationController

  def checkout
    @marchant_id = if params[:ebest_channel].eql?("app")
      Commweb::Payment::APP_MERCHANT_ID
    else
      Commweb::Payment::MERCHANT_ID
    end
  end
end
