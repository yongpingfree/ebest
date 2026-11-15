# frozen_string_literal: true
module MagicBean
  class ReportPage < ApplicationRecord
    # validation macros
    validates_presence_of :name, :content

    # association macros
    belongs_to :creator, class_name: "MagicBean::AdminUser"

    def link_path
      "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/report_pages/#{id}"
    end

    def admin_users
      @admin_users ||= MagicBean::AdminUser.where(id: admin_user_ids)
    end
  end
end
