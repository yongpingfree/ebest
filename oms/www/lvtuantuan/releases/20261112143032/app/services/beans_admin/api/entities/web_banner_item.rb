# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WebBannerItem < Grape::Entity
    expose :id, documentation: { type: Integer }
    expose :position, documentation: { type: Integer }
    expose :mobile_image_url, documentation: { type: String }
    expose :desktop_image_url, documentation: { type: String }
    expose :start_at, documentation: { type: DateTime }
    expose :end_at, documentation: { type: DateTime }
    expose :nav_path_type, documentation: { type: String }
    expose :nav_path_id, documentation: { type: Integer }
    expose :nav_path, documentation: { type: JSON }
  end
end
