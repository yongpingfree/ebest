# frozen_string_literal: true

GrapeSwaggerRails.options.app_name = "eBest"
GrapeSwaggerRails.options.app_url  = ""

GrapeSwaggerRails.options.before_action do

  if m = /(app)|(wms)|(fresh|mgt)/.match(request.path)
    GrapeSwaggerRails.options.url = "/#{m[0]}/api/v1/swagger_doc"
  else
    GrapeSwaggerRails.options.url = "/app/api/v1/swagger_doc"
  end
end

GrapeSwaggerRails.options.api_key_name = "Authorization"
GrapeSwaggerRails.options.api_key_type = "header"
