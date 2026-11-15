# frozen_string_literal: true

module BeansAdmin
  class API::V1::FormItems < ::API

    namespace :form_items, desc: "表格商品 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [
            :cover, :category_id, :minor_category_id, :store_id,
            :translated_searchable_title, :translated_searchable_description,
            :listing_type, :start_selling_at, :notification_emails,
            main_images: [], detail_images: [], channels: [], form_options: []
          ]
        end

        def default_order
          ["created_at DESC"]
        end

        def includes
          [:store, :minor_category, :translations, category: [:translations]]
        end
      end

      desc "表格商品列表", {
        success: API::Entities::FormItem,
        is_array: true
      }
      paginate
      params do
        optional :order_by, type: String, desc: "排序"
        optional :keyword, as: :translated_searchable_title_cont_any, type: String, desc: "搜索商品标题"
        optional :category_parent_id_eq, type: Integer, desc: "一级分类ID"
        optional :category_id_eq, type: Integer, desc: "主商品分类"
        optional :minor_category_id_eq, type: Integer, desc: "次商品分类"
      end
      get do
        authorize! :read, resource_class
        params["category_parent_id_in"] = current_user.can_read_category_ids

        @collection = MagicBean::FormItem.accessible_by(current_ability)

        @collection = @collection.channels_contains(params[:channels]) if params[:channels].present?

        form_items = @collection
          .includes(includes)
          .ransack(ransack_params)

        order_by = (params[:order_by].split(",").map(&:strip).compact + default_order).uniq if params[:order_by].present?
        form_items.sorts = order_by || default_order
        form_items = form_items.result.distinct

        not_destroyable_item_ids = MagicBean::FormItemApplication.all.pluck(:form_item_id).uniq

        present paginate(form_items), with: API::Entities::FormItem, not_destroyable_item_ids: not_destroyable_item_ids
      end

      desc "创建表格商品", {
        success: API::Entities::FormItem
      }
      params do
        requires :all, using: API::Entities::FormItem.documentation.dup.extract!(
          :title_zh_cn, :description_zh_cn, :cover, :category_id, :detail_images,
          :main_images, :listing_type, :channels)
        optional :all, using: API::Entities::FormItem.documentation.dup.extract!(
          :minor_category_id, :start_selling_at)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "表格商品详情", {
          success: API::Entities::FormItem
        }
        get do
          authorize_and_response_resource
        end

        desc "修改表格商品", {
          success: API::Entities::FormItem,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::Item.documentation.dup.extract!(
            :category_id, :minor_category_id, :main_images, :detail_images, :listing_type,
            :start_selling_at, :cover, :channels)
        end
        put do
          authorize_and_update_resource
        end

        desc "删除表格商品", {
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
          if resource.destroyable?
           standard_destroy(resource)
          else
            response_error("该商品不可以被删除")
          end
        end
      end
    end
  end
end
