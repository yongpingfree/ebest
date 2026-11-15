# frozen_string_literal: true

class AppSharesController < ApplicationController
  before_action :set_en_locale, only: [:h5_register_en, :newbie_coupon_templates_en]

  before_action :set_newbie_coupon_templates, only: [
    :h5_register, :register_success, :newbie_coupon_templates,
    :h5_register_en, :register_success_en, :newbie_coupon_templates_en
  ]

  def index
    @target_url = "#{request.host}?#{request.query_string}"
  end

  def h5_register
    @target_url = "#{request.host}?#{request.query_string}"
  end

  def h5_register_en
    @target_url = "#{request.host}?#{request.query_string}"
  end

  def register_success

  end

  def register_success_en; end

  def newbie_coupon_templates
    render partial: "newbie_coupon_template", collection: @newbie_coupon_templates
  end

  def newbie_coupon_templates_en
    render partial: "newbie_coupon_template_en", collection: @newbie_coupon_templates, as: :newbie_coupon_template
  end

  private

  def set_newbie_coupon_templates
    @stores = MagicBean::Store.enabled.order(:id)
    store_id = current_store_id.in?(@stores.pluck(:id)) ? current_store_id : @stores.first.id
    coupon_template_ids = MagicBean::SiteConfig.find_by(store_id: store_id).newbie_coupon_template_ids
    @newbie_coupon_templates = MagicBean::CouponTemplate.includes(:translations).reduction.where(id: coupon_template_ids).order(denominations_in_cent: :desc)
  end

  def current_store_id
    @current_store_id ||= params[:store_id].to_i
  end

  def set_en_locale
    I18n.locale = :en
  end
end
