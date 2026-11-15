# frozen_string_literal: true

module BeansAdmin
  class API::V1::Users < ::API

    helpers ::ApiHelpers::MobileHelper

    namespace :users, desc: "用户列表" do
      helpers BeansAdmin::Helpers::FileUploadHelper

      helpers do
        def includes
          :member
        end

        def permitted_params
          [:is_blocked, :is_host, :accept_marketing_message, :password, :password_confirmation]
        end

        def resource_address_params
          ActionController::Parameters.new(params).permit(
            :first_name, :last_name, :tel_number, :email, :province_name, :city_name,
            :postal_code, :street_number, :street, :detail_info, :unit_number,
            :company_name, :alias_name, :remark, :is_default
          )
        end
      end

      desc "用户列表", {
        success: API::Entities::User,
        is_array: true
      }
      params do
        use :created_at_search
        optional :scope, type: String, desc: "scope", values: ["host"]
        optional :keyword, as: :nickname_or_origin_nickname_or_member_mobile_cont, type: String, desc: "用户昵称搜索"
        optional :deleted_by_user_at_not_null, type: Grape::API::Boolean, desc: "是否已注销"
      end
      paginate
      get do
        @collection = collection.send(params[:scope]) if params[:scope].present?
        authorize_and_response_collection(present: { with: API::Entities::User })
      end

      desc "创建用户", {
        success: API::Entities::User
      }
      params do
        requires :mobile, type: String, desc: "手机号码(前端需要传61)"
        requires :invite_code, type: String, desc: "邀请码"
        requires :password, type: String, desc: "密码"
        requires :password_confirmation, type: String, desc: "确认密码"
      end
      post do
        authorize! :create, MagicBean::User

        check_phone_number!(params[:mobile])
        response_error("用户已存在，不需要重复创建") if MagicBean::Member.exists?(mobile: params[:mobile])

        invited_member = MagicBean::Member.find_by(invite_code: params[:invite_code])
        response_error(I18n.t("grape.users.provide_correct_code")) if invited_member.blank?

        sydney_store = MagicBean::Store.sydney
        member = MagicBean::Member.new(mobile: params[:mobile])
        member.inviter = invited_member
        member.channel = "app"
        member.build_user(
          gender: :unknow,
          nickname: "手机用户#{MagicBean::User.maximum(:id).next}",
          selected_store_id: sydney_store.id,
          locale: I18n.locale,
          sign_up_channel: "app",
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )

        if member.save
          present member.user, with: API::Entities::User
        else
          response_record_error(member)
        end
      rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
        response_error("用户已存在，不需要重复创建")
      end

      desc "导入不接受营销短信用户", {
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
      post "import_not_accept_marketing_users" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:users_file], "xlsx")

        error_messages = []
        user_ids = []

        file_path = params[:users_file][:tempfile].path
        xlsx = Roo::Spreadsheet.open file_path
        result = xlsx.sheet(0).parse

        result.each_with_index do |member_values, i|
          member_mobile = member_values.first.to_s.strip
          member = MagicBean::Member.find_by(mobile: member_mobile)
          if member
            user_ids << member.user_id
          else
            error_messages << "第#{i + 2}行: 找不到该会员"
          end
        end

        response_error(error_messages.join("; ")) if error_messages.present?

        MagicBean::User.where(id: user_ids.uniq).update_all(accept_marketing_message: false)
        response_success
      rescue => e
        response_error(e.message)
      end

      route_param :id do

        desc "更新用户信息", {
          success: API::Entities::User
        }
        params do
          optional :is_blocked, type: Grape::API::Boolean, desc: "是否拉黑"
          optional :is_host, type: Grape::API::Boolean, desc: "是否主播"
          optional :accept_marketing_message, type: Grape::API::Boolean, desc: "是否接收营销短信"
          optional :password, type: String, desc: "密码"
          optional :password_confirmation, type: String, desc: "确认密码"
        end
        put do
          params.extract!(:password) if params[:password].blank?
          authorize_and_update_resource
        end

        desc "用户详情", {
          success: API::Entities::User
        }
        get do
          authorize_and_response_resource
        end

        desc "用户地址列表", {
          success: API::Entities::Address,
          is_array: true
        }
        get "addresses" do
          authorize! :read, resource

          addresses = resource.addresses
          present addresses, with: API::Entities::Address
        end

        desc "更新用户地址", {
          success: API::Entities::Address
        }
        params do
          requires :address_id, type: Integer, desc: "地址ID"
          optional :first_name, type: String, desc: "接收人名"
          optional :last_name, type: String, desc: "接收人姓"
          optional :tel_number, type: String, desc: "电话号码(需传61开头的11位数字)"
          optional :email, type: String, desc: "邮箱"
          optional :province_name, type: String, desc: "省份名"
          optional :city_name, type: String, desc: "城市名"
          optional :postal_code, type: String, desc: "邮政编码"
          optional :street_number, type: String, desc: "门牌号"
          optional :street, type: String, desc: "街道"
          optional :detail_info, type: String, desc: "详细地址"
          optional :unit_number, type: String, desc: "单元号"
          optional :company_name, type: String, desc: "公司名"
          optional :alias_name, type: String, desc: "地址别名"
          optional :remark, type: String, desc: "备注"
          optional :is_default, type: Grape::API::Boolean, desc: "是否默认"
        end
        put "addresses/:address_id" do
          authorize! :update, resource

          address = resource.addresses.find(params[:address_id])
          if address.update(resource_address_params)
            present address, with: API::Entities::Address
          else
            response_record_error(address)
          end
        end

        desc "用户订单", {
          success: API::Entities::SimpleOrder,
          is_array: true
        }
        paginate
        get "orders" do
          authorize! :read, resource

          orders = resource.orders.order(created_at: :desc)
          present paginate(orders), with: API::Entities::SimpleOrder
        end

        desc "用户优惠券", {
          success: API::Entities::Coupon,
          is_array: true
        }
        paginate
        get "coupons" do
          authorize! :read, resource

          coupons = resource.coupons.order(created_at: :desc)
          present paginate(coupons), with: API::Entities::Coupon
        end

        desc "恢复用户账号", {
          success: API::Entities::User
        }
        post "restoration" do
          authorize! :update, resource

          resource.restore_account

          response_resource
        end
      end
    end
  end
end
