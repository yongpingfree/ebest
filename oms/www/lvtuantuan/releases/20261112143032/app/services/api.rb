# frozen_string_literal: true

require "grape-swagger"

class API < Grape::API
  default_format :json
  format :json

  helpers ::ApiHelpers::BaseHelper
  helpers ::ApiHelpers::StrongParametersHelper
  helpers ::ApiHelpers::SharedParamsHelper
  helpers ::ApiHelpers::LocaleHelper

  before do
    I18n.locale = get_locale
  end

  Validators::PositiveInteger
  Validators::NaturalNumber
  Validators::ResourceUrl

  rescue_from ActiveRecord::RecordNotFound do |_|
    rack_response("{\"error\": \"#{I18n.t('error.common.not_found')}\"}", 404)
  end

  rescue_from CanCan::AccessDenied do |_|
    rack_response('{"error": "没有权限进行此操作！"}', 403)
  end
end
