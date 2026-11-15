# frozen_string_literal: true

class QiyukfPushController < ApplicationController
  skip_before_action :verify_authenticity_token

  # doc: http://qiyukf.com/docs/guide/android/4-消息推送.html
  def android
    if should_push?
      PushAppNotificationJob.perform_later(I18n.t("qiyu.title", staff_name: params[:staffName]), params[:content], params[:deviceIdentifier], { nim: "1" }.to_json)
    end

    render plain: ""
  end

  private

  def should_push?
    (Time.current - Time.strptime(params[:time], "%Q") < 5.minutes) && QiyuPushCheckSum.verify(params)
  end
end
