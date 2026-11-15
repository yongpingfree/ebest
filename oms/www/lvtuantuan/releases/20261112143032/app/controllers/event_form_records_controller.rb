# frozen_string_literal: true

class EventFormRecordsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate!, :check_params!, :time_limit

  helper_method :current_user, :current_resource

  def index
    @event_form_records = current_user.event_form_records.where(event_slug: params[:event_slug]).order(id: :asc)
  end

  def create
    @event_form_record = current_user.event_form_records.new(create_params)
    if @event_form_record.save
      # intent to be black
      collect_dragon_balls_answers_success(@event_form_record)
    else
      render_json_error @event_form_record.errors.full_messages.join(", ")
    end
  end

  def update
    if current_resource.update(update_params)
      # intent to be black
      collect_dragon_balls_answers_success(current_resource)
    else
      render_json_error current_resource.errors.full_messages.join(", ")
    end
  end

  def current_user
    @current_user ||= MagicBean::User.registered.find_by(id: session[:user_id])
  end

  def current_resource
    @current_resource ||= current_user.event_form_records.find(params[:id])
  end

  private

  def collect_dragon_balls_answers_success(resource)
    if resource.event_slug.eql?("collect_dragon_balls")
      msg = if resource.completed_at?
        "恭喜您，您的答案全部提交成功，请等待开奖"
      else
        "恭喜您，部分答案保存成功，请继续查找其他答案并提交"
      end
      render_json_success msg
    end
  end

  def time_limit
    return render_json_error("10月1日零时起，活动开始，敬请期待") if params[:event_slug].eql?("collect_dragon_balls") && Time.current < event_start_at
  end

  def event_start_at
    MagicBean::EventPage.dragon_balls_start_at
  end

  def authenticate!
    return render_json_error("用户未授权", :unauthorized) unless current_user
    return render_json_error("非会员用户暂不可提交", :forbidden) unless current_user.member
  end

  def check_params!
    return render_json_error("`event_slug` 参数缺失") if need_event_slug?
  end

  def need_event_slug?
    ("index" == action_name) && params[:event_slug].blank?
  end

  def create_params
    params.permit(:event_slug, data: {})
  end

  def update_params
    params.permit(data: {})
  end
end
