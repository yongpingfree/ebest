# frozen_string_literal: true
module MagicBean
  class Page < ApplicationRecord
    # scope
    default_scope { order(position: :asc, created_at: :desc) }

    # constants
    enum kind: {
      article: 1,
      about_us: 2,
      contact: 3,
      member_info: 4,
      integral_rules: 5,
      delete_user: 6,
      terms_and_conditions: 7,
      privacy_policy: 8,
      overseas_student_application: 9,
      coupon_description: 10,
      cooperation: 11
    }

    # attr related macros

    # association macros

    # validation macros
    validates_presence_of :name, :content

    # callbacks

    # other macros
    ransacker :kind, formatter: proc { |v| kinds[v] }

    def link_path
      "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/pages/#{article? ? id : kind}?app=true"
    end

    def mini_program_path
      "pages/webview-page/webview-page?path=#{link_path}"
    end

    def web_path
      { type: "page", params: { id: id } }.to_json
    end

    def app_path
      { type: "webviewPage", params: { path: link_path } }.to_json
    end
  end
end
