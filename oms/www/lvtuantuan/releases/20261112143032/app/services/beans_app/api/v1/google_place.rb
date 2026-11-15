# frozen_string_literal: true

module BeansApp
  class API::V1::GooglePlace < ::API
    namespace :google_places, desc: "google places api" do
      include GooglePlaceGrape

      current_delivery_area("current_delivery_area")
      google_places_auto_complete_api("autocomplete")
      google_place_detail_api(":place_id")
    end
  end
end
