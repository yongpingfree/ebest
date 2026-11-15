# frozen_string_literal: true
module GooglePlaceGrape
  DETAIL_BASIC_FIELDS = "address_component,geometry,name,place_id,vicinity"
  GOOGLE_PLACE_ERRORS = [
    GooglePlaces::InvalidRequestError,
    GooglePlaces::RequestDeniedError,
    GooglePlaces::OverQueryLimitError,
    GooglePlaces::NotFoundError
  ]
  def self.included(base)
    base.class_eval do
      def self.google_places_auto_complete_api(path = nil)
        desc "google places autocomplete"
        params do
          requires :keyword, type: String, desc: "邮编/地址"
          optional :types, type: String, desc: "请求地址类型。ref: https://developers.google.com/places/web-service/autocomplete#place_types"
          optional :language, type: String, desc: "语言类型", default: "en"
          optional :components, type: String, desc: "components", default: "country:au"
        end
        get (path || "google_places/autocomplete") do
          keyword = params[:keyword]
          ::GooglePlaces::Client.logger.info("user: #{current_user&.id} use predictions_by_input: #{params[:keyword]}")
          places = ::GooglePlaces::Client.client.predictions_by_input(
            keyword,
            types: params[:types],
            language: params[:language] || "en",
            components: params[:components] || "country:au"
          )
          present places, with: ::CommonEntities::GooglePlacesAutocomplete
        rescue *GOOGLE_PLACE_ERRORS
          present []
        end
      end

      def self.google_places_query_api(path = nil)
        desc "google places query"
        params do
          requires :keyword, type: String, desc: "查询信息，例如 'restaurants in Sydney'"
          optional :type, type: String, desc: "查询类型。ref: https://developers.google.com/places/web-service/supported_types#table1"
        end
        get (path || "google_places/query") do
          keyword = params[:keyword]
          redis_key = "spots_query_#{keyword}"
          places_value = RedisClient.get(redis_key)

          if places_value.present?
            places = JSON.parse(places_value).map { |place| GooglePlaces::Spot.new(place["json_result_object"], nil) }
          else
            ::GooglePlaces::Client.logger.info("user: #{current_user&.id} use spots_by_query: #{keyword}")
            places = ::GooglePlaces::Client.client.spots_by_query(keyword, type: params[:type])
            if keyword.length > 2
              RedisClient.set(redis_key, places.to_json)
              RedisClient.expire(redis_key, 604800) # 缓存7天
            end
          end

          present places, with: ::CommonEntities::GooglePlacesDetail
        rescue *GOOGLE_PLACE_ERRORS
          present []
        end
      end

      def self.google_places_nearby_api(path = nil)
        desc "google places nearby search"
        params do
          requires :latitude, type: Float, desc: "纬度"
          requires :longitude, type: Float, desc: "经度"
          optional :types, type: Array[String], desc: "查询类型。ref: https://github.com/qpowell/google_places#retrieving-a-list-of-spots"
        end
        get (path || "google_places/nearby") do
          redis_key = "spots_nearby_lat_#{params[:latitude]}_long_#{params[:longitude]}"
          places_value = RedisClient.get(redis_key)

          if places_value.present?
            places = JSON.parse(places_value).map { |place| GooglePlaces::Spot.new(place["json_result_object"], nil) }
          else
            ::GooglePlaces::Client.logger.info("user: #{current_user&.id} use spots: #{params[:latitude]}, #{params[:longitude]}")
            places = ::GooglePlaces::Client.client.spots(
              params[:latitude],
              params[:longitude],
              types: params[:types],
              detail: true,
              fields: DETAIL_BASIC_FIELDS
            )
            RedisClient.set(redis_key, places.to_json)
            RedisClient.expire(redis_key, 604800) # 缓存7天
          end

          present places, with: ::CommonEntities::GooglePlacesDetail
        rescue *GOOGLE_PLACE_ERRORS
          present []
        end
      end

      def self.current_delivery_area(path = nil)
        desc "get delivery area by google places nearby search",
        skip_authentication: true
        params do
          requires :latitude, type: Float, desc: "纬度"
          requires :longitude, type: Float, desc: "经度"
          optional :types, type: Array[String], desc: "查询类型。ref: https://github.com/qpowell/google_places#retrieving-a-list-of-spots"
        end
        get (path || "google_places/current_delivery_area") do
          delivery_area, detail_place = nil, nil
          redis_key = if current_user
                        "request-google-nearby-count-#{current_user&.id}"
                      else
                        "request-google-nearby-count-#{request.ip}-#{request.user_agent}-#{request.headers["App-Platform"]}-#{request.headers["App-Os-Version"]}"
                      end
          # 如果用户一天内请求超过 MAX_REQUEST_GOOGLE_NEARBY_COUNT 则返回空数据
          request_count = Rails.cache.fetch(redis_key).to_i
          if request_count < GooglePlaces::Client::MAX_REQUEST_GOOGLE_NEARBY_COUNT
            Rails.cache.write(redis_key, request_count += 1, expires_in: (Time.current.end_of_day - Time.current)/60)
            current_location = [params[:latitude], params[:longitude]]
            ::GooglePlaces::Client.logger.info("user: #{current_user&.id} use nearby distance: #{params[:latitude]}, #{params[:longitude]}")
            places = ::GooglePlaces::Client.client.spots(
              params[:latitude],
              params[:longitude],
              types: params[:types],
              rankby: "distance",
              detail: false
            )

            if place = places&.first
              ::GooglePlaces::Client.logger.info("user: #{current_user&.id} use spot place id: #{place&.place_id}")
              detail_place = ::GooglePlaces::Client.client.spot(place&.place_id, fields: DETAIL_BASIC_FIELDS)
              delivery_area = MagicBean::DeliveryArea
                                .near(current_location, 30000, units: :km)
                                .ransack({ suburb_case_insensitive_eq: detail_place.city&.downcase || -1, postal_code_eq: detail_place&.postal_code || -1 })
                                .result.first if detail_place.present?
            end
          end

          present :delivery_area, delivery_area, with: ::BeansApp::API::Entities::DeliveryArea
          present :place, detail_place, with: ::CommonEntities::GooglePlacesDetail
        rescue *GOOGLE_PLACE_ERRORS
          present :delivery_area, delivery_area, with: ::BeansApp::API::Entities::DeliveryArea
          present :place, detail_place, with: ::CommonEntities::GooglePlacesDetail
        end
      end

      def self.google_place_detail_api(path = nil)
        desc "google places detail"
        get (path || "google_places/:place_id") do
          place_id = params[:place_id]
          redis_key = "detail_with_place_id_#{place_id}"
          places_value = RedisClient.get(redis_key)
          if places_value.present?
            place = GooglePlaces::Spot.new(JSON.parse(places_value)["json_result_object"], nil)
          else
            ::GooglePlaces::Client.logger.info("user: #{current_user&.id} use spot place id: #{params[:place_id]}")
            place = ::GooglePlaces::Client.client.spot(params[:place_id], language: "en", components: "country:au", fields: DETAIL_BASIC_FIELDS)
            RedisClient.set(redis_key, place.to_json)
            RedisClient.expire(redis_key, 604800) # 缓存7天
          end
          present place, with: ::CommonEntities::GooglePlacesDetail
        rescue *GOOGLE_PLACE_ERRORS
          response_error("查询出错，请重试。")
        end
      end
    end
  end
end
