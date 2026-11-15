# frozen_string_literal: true

module Wms
  class API::V1::Stores < ::API
    # 分店 API

    namespace :stores, desc: "分店 API" do

      helpers do
        def default_order
          ["created_at desc"]
        end
      end
      desc "取得所有分店", {
        success: API::Entities::Store,
        is_array: true
      }
      paginate
      params do
        use :sign_params
        optional :order_by, type: String, desc: "'created_at desc, updated_at asc' 多字段使用,隔开"
      end
      get do
        response_collection
      end
    end
  end
end
