# frozen_string_literal: true

module BeansAdmin::API::Entities
  class AppDownloadChannel < ::CommonEntities::Model
    expose :code
    expose :name
    expose :qrcode
    expose :ios_views_count
    expose :android_views_count
    expose :other_views_count
  end
end
