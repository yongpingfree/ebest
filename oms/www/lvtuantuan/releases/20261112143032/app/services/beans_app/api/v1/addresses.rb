# frozen_string_literal: true

module BeansApp
  class API::V1::Addresses < ::API

    helpers ::ApiHelpers::MobileHelper

    namespace :addresses, desc: "地址 API" do

      helpers do
        def permitted_params
          [
            :detail_info, :tel_number, :postal_code, :first_name, :last_name, :is_default, :google_place_id, :housing_type,
            :province_name, :city_name, :email, :street, :street_number, :company_name, :alias_name, :unit_number, :remark
          ]
        end

        def default_order
          ["is_default desc", "created_at desc"]
        end

        def end_of_association_chain
          current_user.addresses
        end
      end

      desc "地址列表", {
        success: API::Entities::Address,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建地址", {
        success: API::Entities::Address
      }
      params do
        requires :all, using: API::Entities::Address.documentation.slice(:postal_code, :tel_number, :first_name, :last_name, :province_name, :city_name)
        optional :all, using: API::Entities::Address.documentation.slice(:is_default, :email, :company_name, :alias_name, :unit_number, :remark)
        optional :housing_type, type: String, values: MagicBean::Address.housing_types.keys
      end
      post do
        check_phone_number!(params[:tel_number])
        authorize_and_create_resource
      end

      route_param :id do

        desc "地址详情", {
          success: API::Entities::Address
        }
        get do
          authorize_and_response_resource
        end

        desc "更新地址", {
          success: API::Entities::Address
        }
        params do
          optional :all, using: API::Entities::Address.documentation.slice(
            :postal_code, :tel_number, :first_name, :last_name, :google_place_id, :province_name, :city_name,
            :is_default, :email, :street, :street_number, :company_name, :alias_name, :remark
          )
          optional :housing_type, type: String, values: MagicBean::Address.housing_types.keys
        end
        put do
          authorize_and_update_resource
        end

        desc "删除地址", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
