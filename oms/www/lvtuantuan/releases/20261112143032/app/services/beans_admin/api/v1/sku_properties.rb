# frozen_string_literal: true

module BeansAdmin
  class API::V1::SkuProperties < ::API

    namespace :sku_properties, desc: "SKU 规格名" do

      helpers do
        def permitted_params
          [:text_zh_cn]
        end

        def includes
          [:translations]
        end
      end

      desc "SKU 规格名列表", {
        success: API::Entities::SkuProperty,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "创建 SKU 规格名", {
        success: API::Entities::SkuProperty
      }
      params do
        requires :all, using: API::Entities::SkuProperty.documentation.dup.extract!(:text)
      end
      post do
        params[:text_zh_cn] = params[:text]

        authorize_and_create_resource
      end

      route_param :id do

        desc "编辑 SKU 规格名", {
          success: API::Entities::SkuProperty
        }
        params do
          requires :all, using: API::Entities::SkuProperty.documentation.dup.extract!(:text)
        end
        put do
          params[:text_zh_cn] = params[:text]

          authorize_and_update_resource
        end

        namespace :sku_values, desc: "SKU 规格值" do
          desc "SKU 规格值列表", {
            success: API::Entities::SkuValue,
            is_array: true
          }
          params do
            optional :translations_text_cont, type: String
          end
          paginate
          get do
            sku_property = MagicBean::SkuProperty.find(params[:id])
            present paginate(sku_property.sku_values.includes(:translations).ransack(ransack_params).result.distinct), with: API::Entities::SkuValue
          end

          desc "创建 SKU 规格值", {
            success: API::Entities::SkuValue
          }
          params do
            requires :all, using: API::Entities::SkuValue.documentation.dup.extract!(:text)
          end
          post do
            sku_property = MagicBean::SkuProperty.find(params[:id])
            params[:text_zh_cn] = params[:text]
            sku_value = sku_property.sku_values.new(sku_value_params)
            standard_save(sku_value, API::Entities::SkuValue)
          end
        end
      end
    end
  end
end
