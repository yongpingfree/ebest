# frozen_string_literal: true

module BeansApp::API::Entities
  class MinePageActivitySetting < ::CommonEntities::Model
    expose :name
    expose :icon
    expose :position
    expose :custom_page_en_name
    expose :format_path, as: :path

    # FIXME: 兼容旧版本，后续再移除
    def custom_page_en_name
      object.custom_page&.en_name
    end

    def format_path
      JSON.parse(object.path) if object.path?
    rescue JSON::ParserError
      nil
    end
  end
end
