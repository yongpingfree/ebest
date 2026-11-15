# frozen_string_literal: true
module BeansAdmin
  class API::V1::CustomPages < ::API
    I18N_NAME_MODELS = %w[MagicBean::CategoryTop MagicBean::CategoryChildren MagicBean::AeDropShipperCategoryTop MagicBean::AeDropShipperCategoryChildren MagicBean::Brand]
    I18N_TITLE_MODELS = %w[MagicBean::CouponTemplate MagicBean::Item MagicBean::CustomList MagicBean::FormItem]

    namespace :custom_pages, desc: "CustomPages API" do
      helpers do
        def permitted_params
          [:name, :en_name, :components, :store_id, :bg_color, collaborator_ids: [],
            share_setting_attributes: [
              :id,
              :share_words,
              :share_background_cover,
              :share_cover,
              :search_words,
              :search_cover
            ]
          ]
        end

        def includes
          [:share_setting, :store, :creator]
        end

        def build_resource
          @resource = end_of_association_chain.new(resource_params.merge({
            store_id: current_store_id,
            creator_id: current_user.id
          }))
        end
      end

      desc "page_group_links"
      params do
        optional :keyword, type: String, desc: "搜索关键词"
      end
      get "page_group_links" do
        MagicBean::CustomPage.grouped_links(current_store_id, params[:keyword].to_s)
      end

      desc "page_group_links_v2"
      params do
        requires :link_type, type: String, values: %w(FixedPage MagicBean::Item MagicBean::CategoryTop MagicBean::CategoryChildren MagicBean::AeDropShipperCategoryTop MagicBean::AeDropShipperCategoryChildren MagicBean::CouponTemplate MagicBean::CouponPackage MagicBean::CustomPage MagicBean::CustomList MagicBean::Page MagicBean::EventPage MagicBean::Brand MagicBean::ExternalLink MagicBean::ExternalMiniProgram MagicBean::LiveRoom MagicBean::FormItem MagicBean::HotSellConfig), desc: "资源类型"
        optional :name_cont, type: String, desc: "资源名称"
      end
      paginate
      get "page_links" do
        name_cont = params[:name_cont]
        link_type = params[:link_type]

        if link_type.eql?("FixedPage")
          present paginate(Kaminari.paginate_array(MagicBean::CustomPage::FIXED_PAGES_ARRAY))
        else
          collection =
            case link_type
            when "MagicBean::CategoryTop"
              MagicBean::Category.where(ae_drop_shipper: false).top
            when "MagicBean::CategoryChildren"
              MagicBean::Category.where(ae_drop_shipper: false).children
            when "MagicBean::AeDropShipperCategoryTop"
              MagicBean::Category.where(ae_drop_shipper: true).top
            when "MagicBean::AeDropShipperCategoryChildren"
              MagicBean::Category.where(ae_drop_shipper: true).children
            when "MagicBean::CouponPackage"
              MagicBean::CouponPackage.active
            when "MagicBean::CouponTemplate"
              MagicBean::CouponTemplate.active.where(store_id: [nil, current_store_id])
            when "MagicBean::Item"
              MagicBean::Item.on_sale
            when "MagicBean::FormItem"
              MagicBean::FormItem.online
            when "MagicBean::HotSellConfig"
              MagicBean::HotSellConfig.includes(category: :translations).where(store_id: current_store_id)
            else
              # MagicBean::CustomPage MagicBean::CustomList MagicBean::Page MagicBean::EventPage MagicBean::Brand MagicBean::ExternalLink MagicBean::ExternalMiniProgram
              link_type.constantize
            end

          query_params = if link_type == "MagicBean::CouponTemplate"
                           {}
                         else
                           { store_id_eq: current_store_id }
                         end
          if link_type.in? I18N_NAME_MODELS
            query_params[:translations_name_cont] = name_cont
            query_params[:translations_locale_eq] = "zh-CN"
          elsif link_type.in? I18N_TITLE_MODELS
            query_params[:translations_title_cont] = name_cont
            query_params[:translations_locale_eq] = "zh-CN"
          elsif link_type == "MagicBean::HotSellConfig"
            query_params[:category_translations_name_cont] = name_cont
          else
            query_params[:name_cont] = name_cont
          end

          result = collection.ransack(query_params).result

          present paginate(result), with: ::BeansAdmin::API::Entities::PageLink
        end
      end

      desc "CustomPages list", {
        success: BeansAdmin::API::Entities::CustomPage,
        is_array: true
      }
      paginate
      params do
        optional :name_cont, type: String, desc: "中文名包含"
        optional :en_name_cont, type: String, desc: "英文名名包含"
        optional :order_by, type: String, desc: "排序方式"
      end
      get do
        authorize_and_response_collection
      end

      desc "Create custom_page", {
        success: BeansAdmin::API::Entities::CustomPage
      }
      params do
        requires :name, type: String, desc: "页面中文名"
        requires :en_name, type: String, desc: "页面英文名"
        optional :components, type: String, desc: "组件JSON"
        optional :collaborator_ids, type: Array[Integer], desc: "协作者IDs"
        optional :share_setting_attributes, type: Hash do
          optional :share_words, type: String, desc: "分享语"
          optional :share_background_cover, type: String, desc: "分享海报背景图"
          optional :share_cover, type: String, desc: "分享卡片图"
        end
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "CustomPage detail", {
          success: BeansAdmin::API::Entities::CustomPage
        }
        get do
          authorize_and_response_resource
        end

        desc "Update custom_page", {
          success: BeansAdmin::API::Entities::CustomPage,
          skip_store_id: true
        }
        params do
          optional :name, type: String, desc: "页面中文名"
          optional :en_name, type: String, desc: "页面英文名"
          optional :components, type: String, desc: "组件JSON"
          optional :collaborator_ids, type: Array[Integer], desc: "协作者IDs"
          optional :share_setting_attributes, type: Hash do
            optional :id, type: Integer, desc: "ID"
            optional :share_words, type: String, desc: "分享语"
            optional :share_background_cover, type: String, desc: "分享海报背景图"
            optional :share_cover, type: String, desc: "分享卡片图"
          end
        end
        put do
          if resource.can_be_editted_by?(current_user.id)
            authorize_and_update_resource
          else
            response_error("没有权限更新，请联系创建者#{resource.creator_name}添加协作权限")
          end
        end

        desc "Destroy custom_page", {
          success: BeansAdmin::API::Entities::SuccessfulResult
        }
        delete do
          response_error("小程序/App首页不可删除") if [MagicBean::CustomPage::APP_HOME_PAGE_NAME, MagicBean::CustomPage::MINI_PROGRAM_HOME_PAGE_NAME].include?(resource.en_name)
          if current_user.id == resource.creator_id
            authorize_and_destroy_resource
          else
            response_error("没有权限删除")
          end
        end

        desc "Copy custom_page", {
          success: BeansAdmin::API::Entities::SuccessfulResult
        }
        params do
          requires :name, type: String, desc: "页面中文名"
          requires :en_name, type: String, desc: "页面英文名"
        end
        post "copy" do
          authorize! :create, resource_class
          page = resource.dup
          page.name = params[:name]
          page.en_name = params[:en_name]
          page.creator_id = current_user.id
          if page.save
            response_success
          else
            response_error(page.errors.full_messages.join(","))
          end
        end

        desc "Become app home page", {
          success: BeansAdmin::API::Entities::SuccessfulResult
        }
        put "app_home_page" do
          if current_user.can_set_app_home_page?
            response_error("当前页面已是App首页，无需再次设置") if resource.app_home_page?
            home_page = MagicBean::CustomPage.find_by(store_id: resource.store_id, en_name: MagicBean::CustomPage::APP_HOME_PAGE_NAME)
            ActiveRecord::Base.transaction do
              home_page&.update!(en_name: "#{home_page.en_name}_Arch_#{Time.current.to_i}")
              resource.update!(en_name: MagicBean::CustomPage::APP_HOME_PAGE_NAME)
              MagicBean::OperationRecord.create(operatable: resource, content: "设置为App首页", store_id: current_store_id, channel: "admin", admin_user_id: current_user.id)
            end
            response_success
          else
            response_error("没有权限设置App首页，请联系技术人员添加权限")
          end
        rescue
          response_error("设置App首页失败")
        end
      end
    end
  end
end
