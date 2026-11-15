# frozen_string_literal: true

module BeansAdmin
  class API::V1::ItemTagTypes < ::API

    namespace :item_tag_types, desc: "商品标签类型 API" do

      helpers do
        def permitted_params
          [:name]
        end
      end

      desc "标签类型列表", {
        success: API::Entities::ItemTagType,
        is_array: true
      }
      paginate
      params do
        optional :translations_name_cont, types: String, desc: "名称搜索"
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "导出标签类型列表"
      get "export" do
        authorize! :read, resource_class

        filename = "item-tag-type-#{Date.current.strftime('%Y-%m-%d')}.xlsx"

        package = Axlsx::Package.new do |pkg|
          headers = %w[编号 名称]
          types = %i[integer string]

          pkg.workbook.add_worksheet do |sheet|
            sheet.add_row headers

            collection.each do |item_tag_type|
              row = [item_tag_type.id, item_tag_type.name]
              sheet.add_row(row, types: types)
            end
          end
        end

        content_type "application/octet-stream"
        header["Content-Disposition"] = "attachment; filename=#{filename}"
        env["api.format"] = :binary

        package.to_stream.read
      end

      desc "新增标签类型", {
        success: API::Entities::ItemTagType
      }
      params do
        requires :name, type: String, desc: "品牌名称"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "标签类型详情", {
          success: API::Entities::ItemTagType
        }
        get do
          authorize_and_response_resource
        end

        desc "更新标签类型", {
          success: API::Entities::ItemTagType
        }
        params do
          optional :name, type: String, desc: "品牌名称"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除标签类型", {
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
