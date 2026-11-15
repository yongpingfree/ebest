# frozen_string_literal: true

module Wms
  class API::V1 < API
    prefix "api"
    version "v1"

    before do
      authenticate!
      record_wms_log
    end

    mount Wms::API::V1::Orders
    mount Wms::API::V1::StockKeepingUnits
    mount Wms::API::V1::Stores

    add_swagger_documentation info: {
      title: "WMS API"
    }
  end
end
