# frozen_string_literal: true

module BeansAdmin
  class API::V1::TimeZones < ::API
    namespace :time_zones, desc: "AUS时区接口" do
      desc "AUS时区列表", {
        is_array: true
      }
      get do
        present ActiveSupport::TimeZone.country_zones("AU").map { |zone| { name: zone.name } }
      end
    end
  end
end
