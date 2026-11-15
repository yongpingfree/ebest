# frozen_string_literal: true

module BeansAdmin
  class API::V1::ItemTagGroups < ::API

    namespace :item_tag_groups, desc: "商品标签组 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:item_tag_type_id]
        end

        def includes
          [:translations, :item_tag_type]
        end
      end

      desc "标签组列表", {
        success: API::Entities::ItemTagGroup,
        is_array: true
      }
      paginate
      params do
        optional :name_cont, types: String, desc: "名称搜索"
        optional :item_tag_type_id_eq, type: Integer, desc: "标签类型ID"
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "导出标签类型列表"
      get "export" do
        authorize! :read, resource_class

        filename = "item-tag-group-#{Date.current.strftime('%Y-%m-%d')}.xlsx"

        package = Axlsx::Package.new do |pkg|
          headers = %w[编号 名称 标签类型]
          types = %i[integer string string]

          pkg.workbook.add_worksheet do |sheet|
            sheet.add_row headers

            collection.each do |item_tag_group|
              row = [item_tag_group.id, item_tag_group.name, item_tag_group.item_tag_type_name]
              sheet.add_row(row, types: types)
            end
          end
        end

        content_type "application/octet-stream"
        header["Content-Disposition"] = "attachment; filename=#{filename}"
        env["api.format"] = :binary

        package.to_stream.read
      end

      desc "新增标签组", {
        success: API::Entities::ItemTagGroup
      }
      params do
        requires :name_zh_cn, type: String, desc: "标签组名称"
        requires :item_tag_type_id, type: Integer, desc: "标签类型ID"
        optional :name_zh_tw, type: String, desc: "标签组名称"
        optional :name_en, type: String, desc: "标签组名称"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "标签组详情", {
          success: API::Entities::ItemTagGroup
        }
        get do
          authorize_and_response_resource
        end

        desc "更新标签组", {
          success: API::Entities::ItemTagGroup
        }
        params do
          optional :name_zh_cn, type: String, desc: "标签组名称"
          optional :item_tag_type_id, type: Integer, desc: "标签类型ID"
          optional :name_zh_tw, type: String, desc: "标签组名称"
          optional :name_en, type: String, desc: "标签组名称"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除标签组", {
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
