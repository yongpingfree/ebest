# frozen_string_literal: true

module BeansAdmin
  class API::V1::TopLeftItemTags < ::API

    namespace :top_left_item_tags, desc: "左上角营销标签 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper

      helpers do
        def permitted_params
          [:name, :icon, :start_at, :end_at, :store_id, item_ids: []]
        end

        def includes
          [:store]
        end
      end

      desc "左上角营销标签列表", {
        success: API::Entities::TopLeftItemTag,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增左上角营销标签", {
        success: API::Entities::TopLeftItemTag
      }
      params do
        requires :name, type: String, desc: "标签名称"
        requires :icon, type: String, desc: "标签图标"
        requires :start_at, type: DateTime, desc: "开始时间"
        requires :end_at, type: DateTime, desc: "结束时间"
        optional :item_ids, type: Array[Integer], desc: "商品ID列表"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "左上角营销标签详情", {
          success: API::Entities::TopLeftItemTag
        }
        get do
          authorize_and_response_resource(present: { with: BeansAdmin::API::Entities::TopLeftItemTagDetail })
        end

        desc "更新左上角营销标签", {
          success: API::Entities::TopLeftItemTag
        }
        params do
          optional :name, type: String, desc: "标签名称"
          optional :icon, type: String, desc: "标签图标"
          optional :start_at, type: DateTime, desc: "开始时间"
          optional :end_at, type: DateTime, desc: "结束时间"
          optional :item_ids, type: Array[Integer], desc: "商品ID列表"
        end
        put do
          params.delete(:store_id)
          authorize_and_update_resource
        end

        desc "删除左上角营销标签", {
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

        desc "导入产品", {
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
        post "import_items" do
          response_error("请选择 xlsx 文件") unless check_file_type(params[:users_file], "xlsx")
          error_messages = []
          item_ids = []

          file_path = params[:users_file][:tempfile].path
          xlsx = Roo::Spreadsheet.open file_path
          result = xlsx.sheet(0).parse

          result.each_with_index do |item_values, i|
            item_no, store_id = item_values
            item = MagicBean::Item.find_by(store_id: store_id, no: item_no)
            if item
              item_ids << item.id
            else
              error_messages << "第#{i + 2}行: 找不到该产品"
            end
          end

          response_error(error_messages.join("; ")) if error_messages.present?

          item_ids = ((resource.item_ids || []) + item_ids).uniq
          if resource.update(item_ids: item_ids)
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
