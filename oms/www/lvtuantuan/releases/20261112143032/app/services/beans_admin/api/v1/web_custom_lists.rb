# frozen_string_literal: true
module BeansAdmin
  class API::V1::WebCustomLists < ::API
    namespace :web_custom_lists, desc: "WebCustomLists API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [
            :position, :displayed, :store_id, :items_shuffled, :page_location, :orientation
          ]
        end

        def includes
          [:translations, :store]
        end
      end

      desc "WebCustomLists list", {
        success: API::Entities::WebCustomList,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "Create web_custom_list", {
        success: API::Entities::WebCustomList
      }
      params do
        requires :all, using: API::Entities::WebCustomList.documentation.dup.extract!(:position, :item_ids, :page_location)
        optional :all, using: API::Entities::WebCustomList.documentation.dup.extract!(:displayed)
      end
      post do
        web_custom_list_items_attributes =
          if params[:item_ids].any?
            params[:item_ids].shuffle!(random: Random.new(Time.current.to_i)) if params[:items_shuffled]
            params[:item_ids].map.with_index do |item_id, index|
              { item_id: item_id, position: index }
            end
          else
            []
          end

        web_custom_list = MagicBean::WebCustomList.new(resource_params)
        web_custom_list.web_custom_list_items_attributes = web_custom_list_items_attributes
        if web_custom_list.save
          # 同步相关的item到ES
          # redis_key = web_custom_list.es_item_ids_key
          # Rails.cache.write(redis_key, params[:item_ids].uniq, expires_in: MagicBean::WebCustomList::ES_KEY_REDIS_TIME)
          # ReindexCustomListItemsJob.perform_later(redis_key)
          present web_custom_list, with: ::BeansAdmin::API::Entities::WebCustomList
        else
          response_record_error(web_custom_list)
        end
      end

      desc "从 Excel 导入数据"
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
        optional :id, type: Integer, desc: "自定义商品列表ID"
      end
      post "import" do
        authorize! :create, resource_class

        email = current_admin_user.email
        response_error("请先补充 email 信息，不然没法接收通知结果") if email.blank?
        response_error("请选择门店") if current_store_id.blank?
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        local_file_path = params[:file_message]["tempfile"].path
        original_file_name = params[:file_message]["filename"].force_encoding(Encoding::UTF_8)
        title = File.basename(original_file_name, ".*")
        oss_file_name = "custom_lists/#{Date.current.strftime("%y%m%d")}/#{File.basename(local_file_path)}"
        file_url = aws_upload!(local_file_path, oss_file_name)

        CreateCustomListFromExcelJob.perform_later(title, file_url, current_admin_user.id, current_store_id, "MagicBean::WebCustomList", params[:id].to_i)

        response_success
      end

      route_param :id do
        desc "WebCustomList detail", {
          success: API::Entities::WebCustomList
        }
        get do
          authorize_and_response_resource
        end

        desc "Update web_custom_list", {
          success: API::Entities::WebCustomList,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::WebCustomList.documentation.dup.extract!(:position, :remark, :as_category, :show_discount_rate)
        end
        put do
          authorize! :update, resource
          resource.transaction do
            params[:item_ids].shuffle!(random: Random.new(Time.current.to_i)) if params[:items_shuffled]

            old_item_ids = resource.item_ids
            new_item_ids = params[:item_ids] || []
            # 获取所有变动的item_ids, 同步ES用
            different_item_ids = (old_item_ids + new_item_ids) - (old_item_ids & new_item_ids)

            unless params[:item_ids].eql?(resource.item_ids)
              resource.web_custom_list_items.delete_all
              params[:item_ids].map.with_index do |item_id, index|
                resource.web_custom_list_items.create(item_id: item_id, position: index)
              end
            end
            
            if resource.update(resource_params)
              # 将需要同步的item_ids存到redis，再出发同步ES的job
              # redis_key = resource.es_item_ids_key
              # Rails.cache.write(redis_key, ((Rails.cache.fetch(redis_key) || []) + different_item_ids).uniq, expires_in: MagicBean::WebCustomList::ES_KEY_REDIS_TIME)
              # ReindexCustomListItemsJob.perform_later(redis_key)
              response_resource
            else
              response_record_error(resource)
            end
          end
        end

        desc "Destroy custom_list", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          # 删除的自定义列表也不会出现在app，所以不需要同步ES，等每晚同步就行
          authorize_and_destroy_resource
        end

        desc "导出商品列表"
        get :export do
          authorize! :read, resource_class

          filename = "#{resource.store_name}-#{resource.title}.xlsx"

          package = Axlsx::Package.new do |pkg|
            headers = %w[导入编号* 标题]
            types = %i[string string]

            pkg.workbook.add_worksheet do |sheet|
              sheet.add_row headers, types: types

              resource.items.find_each do |item|
                sheet.add_row [item.no, item.title], types: types
              end
            end
          end

          content_type "application/octet-stream"
          header["Content-Disposition"] = "attachment; filename=#{filename}"
          env["api.format"] = :binary

          present package.to_stream.read
        end
      end
    end
  end
end
