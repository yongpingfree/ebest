# frozen_string_literal: true

module BeansAdmin
  class API::V1::AdminUsers < ::API

    namespace :admin_users, desc: "管理员接口" do
      helpers do
        def default_order
          ["state asc", "created_at desc"]
        end

        def permitted_params
          [:name, :mobile, :role, :email, :password, :receive_notify_email, :password_confirmation, :role_template_id, permissions: [], store_ids: [], can_read_category_ids: []]
        end

        def includes
          [:admin_user_stores, :stores, :role_template]
        end

        def resource
          @resource ||= collection_search_sentence.result.find_by!("#{find_by_key}" => params[find_by_key])
        end
      end

      desc "管理员列表", {
        success: API::Entities::AdminUser,
        is_array: true,
        skip_store_id_filter: true
      }
      paginate
      params do
        optional :keyword, as: :name_or_email_cont, type: String, desc: "关键字"
      end
      get do
        params[:stores_id_eq] = current_store_id if current_store_id && !params[:skip_store_id_filter]
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end

      desc "创建管理员", {
        success: API::Entities::AdminUser
      }
      params do
        requires :all, using: API::Entities::AdminUser.documentation.dup.extract!(:name, :mobile, :role)
        requires :password, type: String, desc: "密码"
        requires :password_confirmation, type: String, desc: "确认密码"
        optional :all, using: API::Entities::AdminUser.documentation.dup.extract!(:email, :receive_notify_email, :can_read_category_ids, :role_template_id)
      end
      post do
        # 分店管理员只能创建分店店员
        response_error("门店管理员只能创建门店店员", 403) if current_user.store_admin? && params[:store_ids].present? && (params[:role] != "store_assistant" || (params[:store_ids] & current_user.store_ids).blank?)

        authorize_and_create_resource
      end

      desc "获取当前管理员的目标页面权限", detail: <<-NOTES.strip_heredoc
      ```json
      {
        "abilities": {
          "goods": [
            "read",
            "create",
            "update",
            "destroy"
          ],
          "categories": [
            "read",
            "create",
            "update",
            "destroy"
          ]
        }
      }
      ```
      NOTES
      params do
        optional :target, type: String, desc: "目标class名称(例如: AdminUser); 如果不传, 则返回当前管理员的所有权限"
      end
      get "abilities" do
        user_abilities = {}
        target = if params[:target].blank?
                   ActiveRecord::Base.connection.tables.map do |model|
                     model.capitalize.singularize.camelize
                   end - [
                    "SchemaMigration",
                    "ArInternalMetadatum",
                    "Tagging",
                    "Tag",
                    "CouponPackagesUser",
                    "FreightTemplatesItem",
                    "AuctionActivity"
                  ] + [
                    "GrouponOrder",
                    "VirtualOrder",
                    "AuctionOrder",
                    "NormalOrder",
                    "WebChannelOrder",
                    "AppChannelOrder",
                    "MiniProgramChannelOrder",
                    "Auction::Activity"
                  ]
                 else
                   [params[:target]]
                 end

        target_additional_actions = {
          "Order" => [:edit_remark, :edit_delivery_time, :fake_deliver, :confirm_order, :audit_refund, :direct_refund, :reopen_after_sale],
          "NormalOrder" => [:edit_remark, :edit_delivery_time, :fake_deliver, :confirm_order, :audit_refund, :direct_refund, :reopen_after_sale],
          "GrouponOrder" => [:edit_remark, :edit_delivery_time, :fake_deliver, :confirm_order, :audit_refund, :direct_refund, :reopen_after_sale, :virtual_deliver, :finish_order],
          "VirtualOrder" => [:edit_remark, :finish_order, :audit_refund, :direct_refund, :reopen_after_sale, :virtual_deliver],
          "AuctionOrder" => [:edit_remark, :finish_order, :audit_refund, :direct_refund, :reopen_after_sale, :virtual_deliver],
          "AfterSale" => [:agree, :refuse, :confirm, :reject],
          "ThirdPartyOrder" => [:return_inventory],
        }

        permissions = current_admin_user.permissions
        target.map do |subject|
          begin
            subject_constantize = "MagicBean::#{subject}".constantize
          rescue => exception
            begin
              subject_constantize = subject.constantize
            rescue => e
              next
            end
          end

          subject_pluralize = subject.underscore.pluralize
          user_abilities[subject_pluralize] = (target_additional_actions[subject] || []) +  [:read, :create, :update, :destroy].select do |action|
            ability_flag = current_ability.can? action, subject_constantize

            if action.eql?(:read) && MagicBean::AdminUser::ADMIN_MENUS.include?(subject_pluralize)
              permissions.include?(subject_pluralize) && ability_flag
            else
              ability_flag
            end
          end
        end.compact

        MagicBean::AdminUser::SPECIAL_MENUS.each do |menu_name|
          if permissions.include?(menu_name)
            user_abilities[menu_name] = (user_abilities[menu_name] || []) + (menu_name.in?(["ae_items", "ae_drop_shipper_categories"]) ? [:read, :update, :destroy] : [:read])
          end
        end

        { abilities: user_abilities }
      end

      desc "菜单栏"
      get "permissions" do
        hash = Hash.new
        MagicBean::AdminUser::ADMIN_MENUS.map do |menu|
          hash[menu] = I18n.t("activerecord.models.#{menu.singularize}")  if current_admin_user.super_admin? ||
                                                                             current_admin_user.permissions.include?(menu)
        end
        hash
      end

      get do
        params[:stores_id_eq] = current_store_id if current_store_id && !params[:skip_store_id_filter]
        authorize_and_response_collection(skip_role_authentication: params[:skip_role_authentication])
      end
      desc "可强制更新SKU价格的管理员列表", {
        success: API::Entities::AdminUser,
        is_array: true,
        skip_store_id_filter: true
      }
      paginate
      get "force_update_price_list" do
        admin_user_ids = Rails.cache.redis.keys("*can_force_update_sku_price").map do |key|
          key.split(":")[1] if Rails.cache.redis.get(key) == "true"
        end.compact

        admin_users = MagicBean::AdminUser.where(id: admin_user_ids)

        present paginate(admin_users), with: API::Entities::MinimalAdminUser
      end

      desc "管理员强制更新SKU价格", {
        success: API::Entities::SuccessfulResult
      }
      params do
        requires :mobile, type: String, desc: "管理员手机号"
      end
      put "set_force_update_price" do
        admin_user = MagicBean::AdminUser.find_by mobile: params[:mobile]
        if admin_user
          authorize! :update, admin_user
          admin_user.can_force_update_sku_price = true
          response_success
        else
          response_error("请输入正确的管理员手机号")
        end
      end

      route_param :id do
        desc "管理员详情", {
          success: API::Entities::AdminUser
        }
        get do
          params[:stores_id_eq] = current_store_id if current_store_id

          authorize_and_response_resource
        end

        desc "修改管理员信息", {
          success: API::Entities::AdminUser
        }
        params do
          optional :all, using: API::Entities::AdminUser.documentation
          optional :password, type: String, desc: "密码"
          optional :password_confirmation, type: String, desc: "确认密码"
        end
        put do
          if params[:password].blank?
            params.extract!(:password)
          end

          authorize! :update, resource

          # 避免非超管越权修改角色，ability限制了非超管只能修改自己的信息，这里再限制下不能修改角色
          response_error("不能修改角色", 403) if !current_user.super_admin? && params[:role].present? && resource.role != params[:role]

          if resource.update(resource_params)
            response_resource
          else
            response_record_error(resource)
          end
        end

        desc "停用/启用管理员", {
          success: API::Entities::AdminUser
        }
        post "toggle_state" do
          authorize_and_run_member_action(:toggle_state)
        end

        desc "接收/不接收待处理订单通知邮件", {
          success: API::Entities::AdminUser
        }
        post "toggle_receive_notify_email" do
          authorize! :update, resource

          if resource.toggle!(:receive_notify_email)
            response_success
          else
            response_record_error(resource)
          end
        end

        desc "移除管理员强制更新SKU价格权限", {
          success: API::Entities::SuccessfulResult
        }
        put "remove_force_update_price" do
          authorize! :update, resource
          resource.can_force_update_sku_price = false
          response_success          
        end
      end
    end
  end
end
