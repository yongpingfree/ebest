# frozen_string_literal: true

module BeansApp::API::Entities
  class ItemBanner < ::CommonEntities::Model
    expose :title, :banner, :start_at, :end_at
    expose :format_path, as: :path

    def format_path
      JSON.parse(object.path) if object.path?
    rescue JSON::ParserError
      nil
    end
  end
end
