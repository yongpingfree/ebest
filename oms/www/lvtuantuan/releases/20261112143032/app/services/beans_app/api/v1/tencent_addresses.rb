# frozen_string_literal: true

module BeansApp
  class API::V1::TencentAddresses < ::API
    namespace :tencent_addresses, desc: "tencent map api" do
      desc "获取用户当前城市",
      skip_authentication: true
      params do
        requires :latitude, type: Float, desc: "纬度"
        requires :longitude, type: Float, desc: "经度"
      end
      get "current_au_suburb" do
        result = TencentMap::Api.get_au_suburb_by_location(params[:latitude], params[:longitude])
        au_suburb = if result.present?
                       suburb = (result["address_component"]["ad_level_4"].presence ||
                         result["address_component"]["ad_level_3"].presence)&.split("(")&.first&.strip
                       postal_code = (result["address"]&.split(",") || [])[-2]&.split(" ")&.last
                       MagicBean::AuSuburb.find_by(name: suburb, postal_code: postal_code)
                     else
                       nil
                     end

        delivery_area = au_suburb.blank? ? nil : MagicBean::DeliveryArea.near([au_suburb.latitude, au_suburb.longitude], 30000, units: :km)
                                                    .order("distance ASC").first
        present :au_suburb, au_suburb, with: API::Entities::AuSuburb
        present :delivery_area, delivery_area, with: API::Entities::DeliveryArea
      end

      desc "根据关键词获取地址列表"
      params do
        requires :keyword, type: String, desc: "关键词"
      end
      get "suggestion_addresses" do
        addresses = TencentMap::Api.suggestion_addresses(params[:keyword])
        present addresses, with: ::CommonEntities::TencentAddress
      end
    end
  end
end
