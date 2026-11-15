# frozen_string_literal: true

class PagesController < ApplicationController
  layout "application"

  def index
    collection = MagicBean::Page.article.ransack(name_or_content_or_desc_cont_any: params[:keyword]).result
    @articles = collection.limit(params[:limit] || 5).offset(params[:offset])

    respond_to do |format|
      format.html do
        @total = collection.size
        @site_config = MagicBean::SiteConfig.default_config
      end
      format.json { render json: @articles }
    end
  end

  def show
    @article = MagicBean::Page.article.find(params[:id])
  end

  def about_us
    @article = MagicBean::Page.find_by(kind: "about_us")

    render :show
  end

  def contact
    @article = MagicBean::Page.find_by(kind: "contact")

    render :show
  end

  def member_info
    @page = MagicBean::Page.find_by(kind: "member_info")
  end

  def integral_rules
    @page = MagicBean::Page.find_by(kind: "integral_rules")
  end

  def delete_user
    @article = MagicBean::Page.find_by(kind: "delete_user")

    render :show
  end

  def terms_and_conditions
    @article = MagicBean::Page.find_by(kind: "terms_and_conditions")

    render :show
  end

  def privacy_policy
    @article = MagicBean::Page.find_by(kind: "privacy_policy")

    render :show
  end

  def overseas_student_application
    @article = MagicBean::Page.find_by(kind: "overseas_student_application")

    render :show
  end

  def coupon_description
    @article = MagicBean::Page.find_by(kind: "coupon_description")

    render :show
  end

  def cooperation
    @article = MagicBean::Page.find_by(kind: "cooperation")

    render :show
  end
end
