# frozen_string_literal: true

module BeansAdmin
  class API::V1::Utils < ::API

    namespace :utils, desc: "工具" do
      include GooglePlaceGrape
      desc "表字段"
      params do
        requires :resource, type: String, desc: "资源名"
      end
      get "columns" do
        begin
          column_names = params[:resource].constantize.column_names
        rescue StandardError => e
          response_error("Model名错误, 请检查后重试...")
        end
        model_name = params[:resource].underscore
        model_name_zh = I18n.t("activerecord.models.#{model_name}")
        columns = column_names.map do |column_name|
          {
            prop: column_name,
            label: I18n.t("activerecord.attributes.#{model_name}.#{column_name}", default: column_name)
          }
        end
        {
          model_name: model_name_zh,
          columns: columns
        }
      end

      google_places_auto_complete_api
      google_places_query_api
      google_place_detail_api
    end
  end
end
