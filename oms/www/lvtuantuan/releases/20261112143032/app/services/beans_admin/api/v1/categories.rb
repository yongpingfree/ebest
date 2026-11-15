# frozen_string_literal: true

module BeansAdmin
  class API::V1::Categories < ::API

    namespace :categories, desc: "商品分类 API" do

      helpers do
        def permitted_params
          resource_class.globalize_attribute_names + [
            :status, :parent_id, :position, :item_position, :icon, :bg_color,
            :display_length, :filter_icon, :can_create_invoice, :need_age_verification,
            :show_on_web, :goto_kind, :search_keywords, :external_url, sort_item_ids: []
          ]
        end

        def default_order
          ["position ASC", "created_at ASC"]
        end

        def resource_params
          params[:sort_item_ids] = (params[:sort_items] || []).map { |item| item["id"] }
          super
        end

        def collection_search_sentence
          @collection = end_of_association_chain.top.accessible_by(current_ability).includes(includes).ransack(ransack_params)
        end

        def includes
          [:translations, children: [:translations]]
        end
      end

      desc "商品分类列表", {
        success: API::Entities::Category,
        is_array: true
      }
      paginate
      params do
        optional :only_parent, type: Boolean, desc: "是否只获取一级分类"
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get do
        entity = params[:only_parent] ? "BeansAdmin::API::Entities::SimpleCategory" : "BeansAdmin::API::Entities::Category"
        params[:ae_drop_shipper_eq] = false unless params[:ae_drop_shipper_eq] == "all"
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication], present: { with: entity.constantize })
      end

      desc "AE海外站点分类列表（跨境购）", {
        success: API::Entities::Category,
        is_array: true
      }
      paginate
      params do
        optional :only_parent, type: Boolean, desc: "是否只获取一级分类"
        optional :skip_role_authentication, type: Boolean, desc: "是否跳过权限验证"
      end
      get "ae_drop_shipper_categories" do
        entity = params[:only_parent] ? "BeansAdmin::API::Entities::SimpleCategory" : "BeansAdmin::API::Entities::Category"
        params[:ae_drop_shipper_eq] = true

        raise CanCan::AccessDenied if !params[:skip_role_authentication] && current_user.permissions.exclude?("ae_drop_shipper_categories")
        present paginate(collection), with: entity.constantize
      end

      desc "AE跨境站点分类列表（非跨境购）", {
        success: API::Entities::AeCategory,
        is_array: true
      }
      paginate
      params do
        optional :keyword, as: :name_cont, type: String, desc: "搜索商品标题、短标题"
      end
      get "ae_categories" do
        categories = MagicBean::AeCategory.ransack(ransack_params).result.order(:id)
        present paginate(categories), with: API::Entities::AeCategory
      end

      desc "二级分类列表", {
        success: API::Entities::SimpleCategory,
        is_array: true
      }
      paginate
      get "children" do
        @collection = end_of_association_chain.children.accessible_by(current_ability)
        authorize_and_response_collection
      end

      desc "新增商品分类", {
        success: API::Entities::Category
      }
      params do
        requires :name_zh_cn, type: String, desc: "分类名称（简体中文）"
        requires :status, values: -> { MagicBean::Category.statuses.keys }, desc: "hidden(隐藏) / show(显示)"
        optional :can_create_invoice, type: Boolean, desc: "下属商品是否能创建发票"
        requires :goto_kind, type: String, desc: "跳转类型"
        optional :parent_id, type: Integer, desc: "父节点 ID"
        requires :position, type: Integer, natural_number: true, desc: "位置"
        optional :icon, type: String, desc: "分类icon"
        optional :filter_icon, type: String, desc: "搜索icon"
        optional :bg_color, type: String, desc: "背景色"
        optional :display_length, type: Integer, desc: "名称显示长度"
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "分类详情", {
          success: API::Entities::Category
        }
        get do
          authorize_and_response_resource(present: { with: BeansAdmin::API::Entities::CategoryDetail })
        end

        desc "更新商品分类", {
          success: API::Entities::Category
        }
        params do
          optional :name, type: String, desc: "分类名称"
          optional :status, values: -> { MagicBean::Category.statuses.keys }, desc: "hidden(隐藏) / show(显示)"
          optional :can_create_invoice, type: Boolean, desc: "下属商品是否能创建发票"
          optional :position, type: Integer, natural_number: true, desc: "位置"
          optional :icon, type: String, desc: "分类icon"
          optional :filter_icon, type: String, desc: "搜索icon"
          optional :bg_color, type: String, desc: "背景色"
          optional :display_length, type: Integer, desc: "名称显示长度"
        end
        put do
          authorize_and_update_resource
        end

        desc "删除商品分类", {
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
