# frozen_string_literal: true

class ReportPagesController < ApplicationController
  layout "application"
  before_action :authenticate!
  include UsersHelper

  def show  
    @page = MagicBean::ReportPage.find(params[:id])
  end

  private
  def authenticate!
    return render_json_error("用户未授权", :unauthorized) unless session[:admin_user_id]
  end
end
