# frozen_string_literal: true

module BeansApp
  class API::V1::CommwebPayments  < ::API
    namespace :commweb_sessions, desc: "CommWeb payments" do
      desc "create commweb session"
      post do
        resp = Commweb::Payment.session(ebest_channel)
        if resp["result"].eql?("SUCCESS")
          present resp, with: ::BeansApp::API::Entities::CommwebSession
        else
          response_error(I18n.t("grape.orders.payment_system_busy"))
        end
      end
    end
  end
end
