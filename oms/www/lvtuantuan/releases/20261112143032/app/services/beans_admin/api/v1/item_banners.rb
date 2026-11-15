# frozen_string_literal: true
module BeansAdmin
  class API::V1::ItemBanners < ::API
    namespace :item_banners, desc: "产品Banner API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def permitted_params
          [
            :title, :banner, :start_at, :end_at, :enabled, :path, :enabled, item_ids: []
          ]
        end
      end

      desc "产品Banner列表", {
        success: API::Entities::SimpleItemBanner,
        is_array: true
      }
      paginate
      params do
        optional :title_cont, type: String, desc: "标题包含"
        optional :start_at_gteq_datetime, type: DateTime, desc: "开始时间大于等于"
        optional :end_at_lteq_datetime, type: DateTime, desc: "结束时间小于等于"
      end
      get do
        authorize_and_response_collection
      end

      desc "创建产品Banner", {
        success: API::Entities::ItemBanner
      }
      params do
        requires :all, using: API::Entities::ItemBanner.documentation.dup.extract!(:title, :start_at, :end_at, :enabled, :path, :banner)
        requires :item_ids, type: Array[Integer]
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "产品Banner详情", {
          success: API::Entities::ItemBanner
        }
        get do
          authorize_and_response_resource
        end

        desc "更新产品Banner活动", {
          success: API::Entities::ItemBanner
        }
        params do
          optional :all, using: API::Entities::ItemBanner.documentation.dup.extract!(:title, :start_at, :end_at, :enabled, :path, :banner)
          optional :item_ids, type: Array[Integer]
        end
        put do
          authorize_and_update_resource
        end

        desc "删除限时产品Banner", {
          success: API::Entities::SuccessfulResult
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
              error_messages << "第#{i + 2}行: 找不到该商品"
            end
          end

          response_error(error_messages.join("; ")) if error_messages.present?

          item_ids = ((resource.item_ids || []) + item_ids).uniq
          resource.update(item_ids: item_ids)
          response_success
        rescue => e
          response_error(e.message)
        end

        namespace :item_banner_clicks, desc: "产品Banner点击统计" do
          desc "产品Banner点击统计列表", {
            success: API::Entities::ItemBannerClick,
            is_array: true
          }
          paginate
          get do
            authorize! :read, MagicBean::ItemBanner

            present paginate(resource.item_banner_clicks), with: API::Entities::ItemBannerClick
          end
        end
      end
    end
  end
end
