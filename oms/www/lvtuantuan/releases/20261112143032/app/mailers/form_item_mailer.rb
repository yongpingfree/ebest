# frozen_string_literal: true

class FormItemMailer < ApplicationMailer
  include ::BeansAdmin::Helpers::ExportHelper

  def new_application
    @form_item_application = params[:form_item_application]
    @form_item = @form_item_application.form_item
    mail(to: params[:emails], subject: "[eBest #{Rails.env} 通知] 新表格产品申请") if params[:emails].present?
  end
end
