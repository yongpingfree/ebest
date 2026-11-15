# frozen_string_literal: true

module BeansApp
  class API::V1::AuSuburbs < ::API

    namespace :au_suburbs, desc: "SUBURBS API" do
      desc "suburbs", {
        success: API::Entities::AuSuburb,
        is_array: true,
        skip_authentication: true
      }
      params do
        optional :keyword, as: :store_name_or_name_or_state_short_name_or_state_name_or_postal_code_cont, type: String, desc: "关键字"
        optional :all, type: Grape::API::Boolean, desc: "获取全部"
      end
      get do
        @suburbs = MagicBean::AuSuburb.ransack(ransack_params).result
        @suburbs = @suburbs.includes(:store).where.not(store_id: nil) unless params[:all]
        present @suburbs.limit(10), with: API::Entities::AuSuburb
      end
    end
  end
end
