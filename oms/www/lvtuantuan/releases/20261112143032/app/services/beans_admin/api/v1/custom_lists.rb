# frozen_string_literal: true
module BeansAdmin
  class API::V1::CustomLists < ::API
    namespace :custom_lists, desc: "CustomLists API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:kind, :remark, :as_category, :position, :store_id, :icon, :show_discount_rate, :items_shuffled, :same_day_delivery, :parent_category_id, :ae_drop_shipper]
        end

        def includes
          [:store, :translations, [parent_category: :translations]]
        end

        def check_same_day_delivery_items
          response_error("当日达列表只能选择当日达产品") if params[:same_day_delivery] && MagicBean::Item.where(id: params[:item_ids]).where.not(item_type: :same_day_delivery).exists?
        end

        def check_ae_drop_shipper_items
          if params[:ae_drop_shipper] && MagicBean::Item.where(id: params[:item_ids]).where(ae_drop_shipper: false).exists?
            response_error("跨境购列表只能选择跨境购产品")
          elsif !params[:ae_drop_shipper] && MagicBean::Item.where(id: params[:item_ids]).where(ae_drop_shipper: true).exists?
            response_error("非跨境购列表不能选择跨境购产品")
          end
        end

        # 猜你喜欢和新品都无需设置产品
        def reset_not_normal_columns
          if params[:kind] != "normal"
            params[:item_ids] = []
            params[:items_shuffled] = false
            params[:same_day_delivery] = false
          end
        end
      end

      desc "CustomLists list", {
        success: API::Entities::CustomList,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "Create custom_list", {
        success: API::Entities::CustomList
      }
      params do
        requires :all, using: API::Entities::CustomList.documentation.dup.extract!(:kind, :position, :item_ids)
        optional :all, using: API::Entities::CustomList.documentation.dup.extract!(:remark, :as_category, :show_discount_rate)
      end
      post do
        reset_not_normal_columns
        check_same_day_delivery_items
        check_ae_drop_shipper_items

        custom_list_items_attributes =
          if params[:item_ids].any?
            params[:item_ids].shuffle!(random: Random.new(Time.current.to_i)) if params[:items_shuffled]
            params[:item_ids].map.with_index do |item_id, index|
              { item_id: item_id, position: index, store_id: params[:store_id] }
            end
          else
            []
          end

        custom_list = MagicBean::CustomList.new(resource_params)
        custom_list.custom_list_items_attributes = custom_list_items_attributes
        if custom_list.save
          # 同步相关的item到ES
          # redis_key = custom_list.es_item_ids_key
          # Rails.cache.write(redis_key, params[:item_ids].uniq, expires_in: MagicBean::CustomList::ES_KEY_REDIS_TIME)
          # ReindexCustomListItemsJob.perform_later(redis_key)
          present custom_list, with: ::BeansAdmin::API::Entities::CustomList
        else
          response_record_error(custom_list)
        end
      end

      desc "清空 redis 缓存"
      post "empty_redis" do
        authorize! :read, resource_class

        MagicBean::CustomList.clear_all_redis_keys

        response_success
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

        CreateCustomListFromExcelJob.perform_later(title, file_url, current_admin_user.id, current_store_id, "MagicBean::CustomList", params[:id].to_i)

        response_success
      end

      route_param :id do
        desc "CustomList detail", {
          success: API::Entities::CustomList
        }
        get do
          authorize_and_response_resource
        end

        desc "Update custom_list", {
          success: API::Entities::CustomList,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::CustomList.documentation.dup.extract!(:position, :remark, :as_category, :show_discount_rate)
        end
        put do
          authorize! :update, resource
          reset_not_normal_columns
          check_same_day_delivery_items
          check_ae_drop_shipper_items

          resource.transaction do
            params[:item_ids].shuffle!(random: Random.new(Time.current.to_i)) if params[:items_shuffled]

            old_item_ids = resource.item_ids
            new_item_ids = params[:item_ids] || []
            # 获取所有变动的item_ids, 同步ES用
            different_item_ids = (old_item_ids + new_item_ids) - (old_item_ids & new_item_ids)

            unless params[:item_ids].eql?(resource.item_ids)
              resource.custom_list_items.delete_all
              params[:item_ids].map.with_index do |item_id, index|
                resource.custom_list_items.create(item_id: item_id, position: index, store_id: params[:store_id])
              end
            end

            if resource.update(resource_params)
              # 将需要同步的item_ids存到redis，再出发同步ES的job
              # redis_key = resource.es_item_ids_key
              # Rails.cache.write(redis_key, ((Rails.cache.fetch(redis_key) || []) + different_item_ids).uniq, expires_in: MagicBean::CustomList::ES_KEY_REDIS_TIME)
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

              resource.items.each do |item|
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
