# frozen_string_literal: true

module BeansApp
  class API::V1::Stores < ::API

    namespace :stores, desc: "分店API" do
      helpers do
        def includes
          [:default_au_suburb]
        end

        def end_of_association_chain
          resource_class.enabled
        end
      end

      desc "获取用户当前分店", {
        skip_authentication: true
      }
      params do
        optional :latitude, type: Float, desc: "纬度"
        optional :longitude, type: Float, desc: "经度"
        optional :suburb_name, type: String
        optional :postal_code, type: String
        all_or_none_of :latitude, :longitude
        all_or_none_of :suburb_name, :postal_code
      end
      get "current_store" do
        # 1. 根据提交的经纬度计算出最近的 suburb, 找不到则等得到 store 之后，拿 store 的第一个 suburb
        # 2. 根据 suburb 查找 store, 找不到则返回默认 store
        # 3. 根据 suburb 查找 store 下的 delivery_area

        current_suburb =
          if params[:latitude].present? && params[:longitude].present?
            MagicBean::AuSuburb.near([params[:latitude], params[:longitude]], 30000, units: :km).first
          elsif params[:suburb_name].present? && params[:postal_code].present?
            MagicBean::AuSuburb.ransack(name_case_insensitive_eq: params[:suburb_name]&.downcase, postal_code_eq: params[:postal_code]).result.first
          end

        # 没有设置默认店铺时，需要拿第一个store
        current_store = MagicBean::Store.ransack(au_suburbs_id_eq: current_suburb&.id || -1).result.first || MagicBean::Store.default.first || MagicBean::Store.first

        current_suburb ||= current_store.au_suburbs.find_by(name: "Sydney", postal_code: "2000") || current_store.au_suburbs.first

        delivery_area =
          if current_suburb
            MagicBean::DeliveryArea
              .near([current_suburb.latitude, current_suburb.longitude], 30000, units: :km)
              .ransack({ suburb_case_insensitive_eq: current_suburb.name&.downcase || -1, postal_code_eq: current_suburb&.postal_code || -1 })
              .result
              .order("distance ASC")
              .first
          else
            nil
          end

        present :current_store, current_store, with: API::Entities::Store
        present :current_suburb, current_suburb, with: API::Entities::AuSuburb
        present :delivery_area, delivery_area, with: API::Entities::DeliveryArea
      end

      desc "分店列表", {
        success: API::Entities::Store,
        is_array: true,
        skip_authentication: true
      }
      paginate
      get do
        authorize_and_response_collection
      end
    end
  end
end
