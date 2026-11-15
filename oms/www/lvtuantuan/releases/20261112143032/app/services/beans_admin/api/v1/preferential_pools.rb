# frozen_string_literal: true

module BeansAdmin
  class API::V1::PreferentialPools < ::API
    # 优惠池 API
    namespace :preferential_pools, desc: "优惠池 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def default_order
          ["id desc"]
        end

        def permitted_params
          resource_class.globalize_attribute_names + [:kind, :threshold_kind, :at_least_amount_in_yuan, :at_least_quantity, :start_at, :end_at, :enabled, :store_id, preferences: {}, sku_ids: []]
        end

        def check_skus_store
          errors = []
          if params[:sku_ids].present?
            skus = MagicBean::StockKeepingUnit.includes(:item).where(id: params[:sku_ids]).where.not(store_id: resource.store_id)
            if skus.present?
              title = skus.map { |sku| sku.title }.join("; ")
              errors << "SKU: #{title} 不是该优惠池门店SKU"
            end
          end

          if params[:kind] == "gift" && params[:preferences] && params[:preferences][:skus].present?
            gift_sku_ids = params[:preferences][:skus].map { |sku| sku[:sku_id] }
            gift_skus = MagicBean::StockKeepingUnit.includes(:item).where(id: gift_sku_ids).where.not(store_id: resource.store_id)
            if gift_skus.present?
              title = gift_skus.map { |sku| sku.title }.join("; ")
              errors << "赠品SKU: #{title} 不是该优惠池门店SKU"
            end
          end

          response_error("#{errors.join(", ")}，请检查右上角门店再选择商品") if errors.present?
        end
      end

      desc "优惠池列表", {
        success: API::Entities::SimplePreferentialPool,
        is_array: true
      }
      params do
        optional :scope, type: String, desc: "scope", values: ["active", "enabled"]
      end
      paginate
      get do
        @collection = collection.send(params[:scope]) if params[:scope].present?
        authorize_and_response_collection
      end

      desc "新增优惠池", {
        success: API::Entities::PreferentialPool
      }
      params do
        requires :all, using: API::Entities::PreferentialPool.documentation.dup.extract!(:title_zh_cn, :kind, :threshold_kind, :start_at, :end_at, :enabled, :preferences, :sku_ids)
        optional :all, using: API::Entities::PreferentialPool.documentation.dup.extract!(:at_least_amount_in_cent, :at_least_quantity)
      end
      post do
        authorize_and_create_resource
      end

      desc "停用/启用池详情", detail: API::Entities::SuccessfulResult
      params do
        optional :id, type: Integer, desc: "池详情ID"
      end
      put "toggle_enabled" do
        authorize! :enable, MagicBean::PreferentialPool

        pool = MagicBean::PreferentialPool.find(params[:id])

        if pool.toggle(:enabled).save
          response_success
        else
          response_error(pool.errors.full_messages.join(", "))
        end
      end

      route_param :id do
        helpers do
          def current_preferential_pool
            @current_pool ||= MagicBean::PreferentialPool.find params[:id]
          end
        end

        desc "优惠池详情", {
          success: API::Entities::PreferentialPool
        }
        get do
          authorize_and_response_resource
        end

        desc "更新优惠池", {
          success: API::Entities::PreferentialPool,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::PreferentialPool.documentation.dup.extract!(:title, :enabled, :time_kind, :details_image, :remarks, :user_kind, :item_ids, :channel, :category_ids, :sub_category_ids, :brand_ids, :delivery_types, :payment_types)
        end
        put do
          check_skus_store
          authorize_and_update_resource
        end

        desc "删除优惠池", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          authorize_and_destroy_resource
        end

        desc "导入SKU", {
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
          requires :users_file, type: File, desc: "支持xlsx文件"
        end
        post "import_skus" do
          response_error("请选择 xlsx 文件") unless check_file_type(params[:users_file], "xlsx")

          error_messages = []
          sku_ids = []

          file_path = params[:users_file][:tempfile].path
          xlsx = Roo::Spreadsheet.open file_path
          result = xlsx.sheet(0).parse

          result.each_with_index do |item_values, i|
            sku_no, store_id = item_values
            sku = MagicBean::StockKeepingUnit.find_by(store_id: store_id, no: sku_no)
            if sku
              sku_ids << sku.id
            else
              error_messages << "第#{i + 2}行: 找不到该SKU"
            end
          end

          response_error(error_messages.join("; ")) if error_messages.present?

          sku_ids = ((resource.sku_ids || []) + sku_ids).uniq
          if resource.update(sku_ids: sku_ids)
            response_success
          else
            response_error(resource.errors.full_messages.join(", "))
          end
        rescue => e
          response_error(e.message)
        end
      end
    end
  end
end
