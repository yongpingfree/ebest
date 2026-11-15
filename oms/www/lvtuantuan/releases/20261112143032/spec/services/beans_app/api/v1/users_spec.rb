# frozen_string_literal: true

require "rails_helper"

RSpec.describe BeansApp::API::V1::Users, type: :request do
  let(:user_sign_up_path) { "/app/api/v1/user/sign_up" }
  let(:mobile) { "61412345678" }
  let(:email) { "test@example.com" }
  let(:password) { "eBest#1234" }
  # 万能码已仅限 development（P0 安全修复），测试环境需向 Redis 预置真实短信码
  let(:verification_code) { "654321" }
  let(:user_params) {
    { mobile: mobile, email: email, password: password, password_confirmation: password, code: verification_code }
  }

  before do
    MagicBean::VerificationCode.new(mobile, :register_member).code = verification_code
  end

  describe "User sign up" do
    it "creates a new user" do
      original_user_count = MagicBean::User.count
      original_member_count = MagicBean::Member.count

      post user_sign_up_path, params: user_params

      expect(response).to have_http_status(:created)

      expect(MagicBean::User.count).to eq(original_user_count + 1)
      expect(MagicBean::Member.count).to eq(original_member_count + 1)

      new_member = MagicBean::Member.order(created_at: :asc).last
      expect(new_member.email).to eq(email)
      expect(new_member.mobile).to eq(mobile)
    end

    it "fails if password confirmation does not match password" do
      post user_sign_up_path, params: user_params.merge(password_confirmation: "wrong_password")
      expect(response).to have_http_status(:bad_request)
    end
  end
end
