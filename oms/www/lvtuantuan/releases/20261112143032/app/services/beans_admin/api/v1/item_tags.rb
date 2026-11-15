# frozen_string_literal: true

module BeansAdmin
  class API::V1::ItemTags < ::API

    namespace :item_tags, desc: "商品标签项 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [:item_tag_group_id]
        end

        def includes
          [:translations, item_tag_group: [:translations, :item_tag_type]]
        end
      end

      desc "标签项列表", {
        success: API::Entities::ItemTag,
        is_array: true
      }
      paginate
      params do
        optional :translations_name_cont, types: String, desc: "名称搜索"
        optional :item_tag_group_id_eq, type: Integer, desc: "标签组ID"
        optional :item_tag_group_item_tag_type_id_eq, type: Integer, desc: "标签类型ID"
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
        optional :order_by, type: String, values: -> { ["created_at asc", "created_at desc", "updated_at asc", "updated_at desc", "item_tag_relations_count asc", "item_tag_relations_count desc", "item_tag_translations.name desc", "item_tag_translations.name asc"] }, desc: "排序"
      end
      get do
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "导出标签项列表"
      get "export" do
        authorize! :read, resource_class

        filename = "item-tag-#{Date.current.strftime('%Y-%m-%d')}.xlsx"

        package = Axlsx::Package.new do |pkg|
          headers = %w[编号 名称 标签组 标签类型]
          types = %i[integer string string string]

          pkg.workbook.add_worksheet do |sheet|
            sheet.add_row headers

            collection.each do |item_tag|
              row = [item_tag.id, item_tag.name, item_tag.item_tag_group_name, item_tag.item_tag_type_name]
              sheet.add_row(row, types: types)
            end
          end
        end

        content_type "application/octet-stream"
        header["Content-Disposition"] = "attachment; filename=#{filename}"
        env["api.format"] = :binary

        package.to_stream.read
      end

      desc "新增标签项", {
        success: API::Entities::ItemTag
      }
      params do
        requires :name_zh_cn, type: String, desc: "标签名称"
        requires :item_tag_group_id, type: Integer, desc: "标签组ID"
        optional :name_zh_tw, type: String, desc: "标签名称"
        optional :name_en, type: String, desc: "标签名称"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "标签项详情", {
          success: API::Entities::ItemTag
        }
        get do
          authorize_and_response_resource
        end

        desc "更新标签项", {
          success: API::Entities::ItemTag
        }
        params do
          optional :name_zh_cn, type: String, desc: "标签名称"
          optional :item_tag_group_id, type: Integer, desc: "标签组ID"
          optional :name_zh_tw, type: String, desc: "标签名称"
          optional :name_en, type: String, desc: "标签名称"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除标签项", {
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
