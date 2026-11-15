# frozen_string_literal: true

class MagicBean::EventPage < ApplicationRecord
  has_many :event_form_records

  def users_count
    event_form_records.map(&:user_id).uniq.count
  end

  def link_path
    "#{Rails.application.credentials.dig(Rails.env.to_sym, :domain)}/event_pages/#{slug}"
  end

  def mini_program_path
    "pages/webview-page/webview-page?path=#{link_path}"
  end

  def app_path
    { type: "webviewPage", params: { path: link_path } }.to_json
  end

  def self.dragon_balls_start_at
    (Rails.env.production? ? "2020-10-1 00:00" : "2020-9-30 18:00").in_time_zone
  end
end
