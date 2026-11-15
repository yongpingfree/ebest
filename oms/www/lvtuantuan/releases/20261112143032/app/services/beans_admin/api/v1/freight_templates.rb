# frozen_string_literal: true

module BeansAdmin
  class API::V1::FreightTemplates < ::API

    namespace :freight_templates, desc: "默认运费模版 API" do
      helpers do
        def resource_class
          MagicBean::DefaultFreightTemplate
        end

        def resource
          @resource ||= end_of_association_chain.includes([exceptional_freight_templates: [:au_suburb_freight_templates, :translations, au_suburbs: [:store]]]).find_by!("#{find_by_key}" => params[find_by_key])
        end

        def permitted_params
          resource_class.globalize_attribute_names + [
            :first_kg_charge_in_yuan, :second_kg_charge_in_yuan, :continued_weight_charge_in_yuan, :extra_charge_in_yuan,
            :first_kg_cost_in_yuan, :second_kg_cost_in_yuan, :continued_weight_cost_in_yuan, :extra_cost_in_yuan, :long_distance_fee_in_yuan,
            :free_shipping_amount_in_yuan, :app_free_shipping_amount_in_yuan, :mini_program_free_shipping_amount_in_yuan, :web_free_shipping_amount_in_yuan,
            :ae_drop_shipper,
            :delivery_type, :store_id,
            exceptional_freight_templates_attributes: resource_class.globalize_attribute_names + [
              :first_kg_charge_in_yuan, :second_kg_charge_in_yuan, :continued_weight_charge_in_yuan, :extra_charge_in_yuan,
              :first_kg_cost_in_yuan, :second_kg_cost_in_yuan, :continued_weight_cost_in_yuan, :extra_cost_in_yuan, :long_distance_fee_in_yuan,
              :free_shipping_amount_in_yuan,  :app_free_shipping_amount_in_yuan, :mini_program_free_shipping_amount_in_yuan, :web_free_shipping_amount_in_yuan,
              :id, :store_id, :_destroy, au_suburb_ids: []
            ]
          ]
        end

        def includes
          [:translations]
        end
      end

      desc "默认运费模版列表", {
        success: API::Entities::DefaultFreightTemplate
      }
      paginate
      params do
        optional :translations_name_cont, type: String
        optional :delivery_type_eq, type: String, values: -> { ::MagicBean::FreightTemplate.delivery_types.keys }
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "新增运费模版", {
        success: API::Entities::DefaultFreightTemplate
      }
      params do
        requires :all, using: API::Entities::DefaultFreightTemplate.documentation.except(:id, :name, :exceptional_freight_templates, :free_shipping_amount_in_yuan, :app_free_shipping_amount_in_yuan, :mini_program_free_shipping_amount_in_yuan, :web_free_shipping_amount_in_yuan)
        optional :all, using: API::Entities::DefaultFreightTemplate.documentation.slice(:free_shipping_amount_in_yuan, :app_free_shipping_amount_in_yuan, :mini_program_free_shipping_amount_in_yuan, :web_free_shipping_amount_in_yuan)
        optional :exceptional_freight_templates_attributes, type: Array do
          optional :all, using: API::Entities::ExceptionalFreightTemplate.documentation.except(:id, :freight_template_id, :delivery_type)
        end
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "运费模板详情", {
          success: API::Entities::DefaultFreightTemplate
        }
        get do
          authorize_and_response_resource
        end

        desc "更新运费模版", {
          success: API::Entities::DefaultFreightTemplate,
          skip_store_id: true,
          detail: <<-NOTES.strip_heredoc
            如果需要删除特殊省份运费模版，需要在 `exceptional_freight_templates_attributes` 的每条记录里增加 `"_destroy": true` 的参数。
          NOTES
        }
        params do
          optional :all, using: API::Entities::DefaultFreightTemplate.documentation.except(:id, :exceptional_freight_templates)
          optional :exceptional_freight_templates_attributes, type: Array do
            optional :all, using: API::Entities::ExceptionalFreightTemplate.documentation.except(:id, :freight_template_id, :delivery_type)
            optional :id, type: Integer, desc: "特殊省份运费模版 ID"
            optional :freight_template_id, type: Integer, desc: "归属的默认运费模版ID"
          end
        end
        put do
          authorize_and_update_resource
        end

        desc "删除运费模板", {
          success: API::Entities::DefaultFreightTemplate
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
