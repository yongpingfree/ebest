# frozen_string_literal: true
module BeansAdmin
  class API::V1::PromoCodeTemplates < ::API
    namespace :promo_code_templates, desc: "PromoCodeTemplates API" do
      helpers do
        def permitted_params
          [
            :title, :enabled, :start_on, :end_on, :remark, :display_in_item_detail, :user_kind, :use_times_kind, :purpose,
            promo_stock_keeping_units_attributes: [
              :price_in_cent, :quantity, :stock_keeping_unit_id, :id, :_destroy
            ]
          ]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge({
            store_id: current_store_id
          }))
        end

        def includes
          [:promo_codes]
        end
      end

      desc "PromoCodeTemplates list", {
        success: API::Entities::PromoCodeTemplate,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "Create PromoCodeTemplate", {
        success: API::Entities::PromoCodeTemplate
      }
      params do
        requires :all, using: API::Entities::PromoCodeTemplate.documentation.slice(:title, :enabled, :start_on, :end_on, :purpose)
        optional :all, using: API::Entities::PromoCodeTemplate.documentation.slice(:remark)
        optional :promo_stock_keeping_units_attributes, type: Array do
          requires :all, using: API::Entities::PromoStockKeepingUnit.documentation.slice(:price_in_cent, :quantity, :stock_keeping_unit_id)
        end
      end
      post do
        authorize_and_create_resource
      end

      desc "停用/启用", detail: API::Entities::SuccessfulResult
      params do
        optional :ids, type: Array[Integer], desc: "模板详情ID"
      end
      put "toggle_enabled" do
        authorize! :enable, MagicBean::PromoCodeTemplate
        MagicBean::PromoCodeTemplate.where(id: params[:ids]).find_each do |pct|
          pct.toggle!(:enabled)
        end
        response_success
      end

      desc "导出列表"
      get "export" do
        response_error("您还没有设置邮箱。") if current_admin_user.email.blank?

        check_export_list_count

        options = {
          email: current_admin_user.email,
          order_by: params[:order_by] || default_order,
          ransack_params: ransack_params
        }

        options = encrypt_params(options)

        ExportPromoCodesJob.perform_later(options)

        present({ message: "导出任务后台执行，请稍后查看邮箱。" })
      end

      route_param :id do
        desc "PromoCodeTemplate detail", {
          success: API::Entities::PromoCodeTemplate
        }
        get do
          authorize_and_response_resource
        end

        desc "Update promo_code_template", {
          success: API::Entities::PromoCodeTemplate
        }
        params do
          optional :all, using: API::Entities::PromoCodeTemplate.documentation.slice(:title, :enabled, :start_on, :end_on)
          optional :all, using: API::Entities::PromoCodeTemplate.documentation.slice(:remark)
          optional :promo_stock_keeping_units_attributes, type: Array do
            optional :all, using: API::Entities::PromoStockKeepingUnit.documentation.slice(:id, :price_in_cent, :quantity, :stock_keeping_unit_id)
            optional :_destroy, type: Boolean
          end
        end
        put do
          authorize_and_update_resource
        end

        desc "Destroy promo_code_template", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end

        desc "生成 Promo Code", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        params do
          requires :quantity, type: Integer, desc: "数量"
          optional :custom_code, type: String, desc: "自订 Code"
        end
        post "generate_promo_codes" do
          authorize! :create, MagicBean::PromoCode

          if params[:custom_code].present?
            resource.promo_codes.create(total_avaliable_count: params[:quantity], code: params[:custom_code].strip)
          else
            resource.enqueue_generate_promo_codes_job(params[:quantity])
            response_success
          end
        end
      end
    end
  end
end
