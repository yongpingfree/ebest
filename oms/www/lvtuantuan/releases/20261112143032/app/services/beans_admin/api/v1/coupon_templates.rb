# frozen_string_literal: true

module BeansAdmin
  class API::V1::CouponTemplates < ::API
    # 优惠券模板 API

    namespace :coupon_templates, desc: "优惠券模板 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def default_order
          ["enabled desc", "id desc"]
        end

        def includes
          [:store, :translations]
        end

        def permitted_params
          resource_class.globalize_attribute_names + [
            :title, :display_in_item_detail, :kind, :denominations_in_yuan, :min_denominations_in_yuan,
            :max_denominations_in_yuan, :at_least_amount_in_yuan, :discount, :need_at_least_amount,
            :time_kind, :time_limit_in_day, :start_at, :end_at, :details_image, :enabled, :remarks,
            :user_kind, :cost_accounting, :target_kind, :usage_kind, :channel, :store_id, :party, :assign_start_at,
            :assign_end_at, :assign_total_quantity, :max_random_reduction_count, :updated_by_admin,
            category_ids: [], item_ids: [], sub_category_ids: [], brand_ids: [], delivery_types: [],
            payment_types: [], custom_list_ids: [],
            random_reduction_coupon_template_rules_attributes: [
              :id, :_destroy, :max_quantity, :min_amount_in_yuan, :max_amount_in_yuan
            ]
          ]
        end

        def end_of_association_chain
          if params["include_nil_store"]
            store_id = params.delete("store_id_eq")
            resource_class.where(store_id: [nil, store_id])
          else
            resource_class
          end
        end

        def collection_search_sentence
          if params[:coupon_start_at].present? && params[:coupon_end_at].present?
            coupon_start_at = params[:coupon_start_at].to_datetime.in_time_zone.beginning_of_day
            coupon_end_at = params[:coupon_end_at].to_datetime.in_time_zone.end_of_day
            @collection = end_of_association_chain.accessible_by(current_ability).includes(includes)
                            .select("coupon_templates.*, count(distinct used_coupons.id) as used_count, count(distinct assigned_coupons.id) as assigned_count")
                            .joins("LEFT OUTER JOIN coupons as used_coupons ON coupon_templates.id = used_coupons.coupon_template_id AND used_coupons.status = 2 AND used_coupons.used_at between '#{coupon_start_at}' and '#{coupon_end_at}'")
                            .joins("LEFT OUTER JOIN coupons as assigned_coupons ON coupon_templates.id = assigned_coupons.coupon_template_id AND assigned_coupons.user_id is NOT NULL AND assigned_coupons.assigned_at between '#{coupon_start_at}' and '#{coupon_end_at}'")
                            .ransack(ransack_params)
          else
            super
          end
        end
      end

      desc "优惠券模板列表", {
        success: API::Entities::CouponTemplate,
        is_array: true
      }
      params do
        optional :scope, type: String, desc: "scope", values: ["active", "enabled"]
        optional :coupon_start_at, type: Date, desc: "统计优惠券开始于"
        optional :coupon_end_at, type: Date, desc: "统计优惠券结束于"
      end
      paginate
      get do
        validate_export_date_params(
          params[:coupon_start_at],
          params[:coupon_end_at]
        )

        @collection = collection.send(params[:scope]) if params[:scope].present?
        authorize_and_response_collection
      end

      desc "新增优惠券模板", {
        success: API::Entities::CouponTemplate
      }
      params do
        requires :all, using: API::Entities::CouponTemplate.documentation.dup.extract!(:enabled, :details_image, :user_kind, :target_kind, :kind, :time_kind, :channel, :party)
        optional :all, using: API::Entities::CouponTemplate.documentation.dup.extract!(:cost_accounting, :denominations_in_cent, :min_denominations_in_cent, :maxdenominations_in_cent, :discount,
                                                                                       :at_least_amount_in_cent, :need_at_least_amount, :time_limit_in_day, :start_at, :end_at,
                                                                                       :remarks, :custom_list_ids, :item_ids, :category_ids, :sub_category_ids, :brand_ids, :delivery_types, :payment_types,
                                                                                       :assign_start_at, :assign_end_at, :assign_total_quantity)
      end
      post do
        params[:updated_by_admin] = true
        authorize_and_create_resource
      end

      desc "停用/启用券模板详情", detail: API::Entities::SuccessfulResult
      params do
        optional :ids, type: Array[Integer], desc: "券模板详情ID"
      end
      put "toggle_enabled" do
        authorize! :enable, MagicBean::CouponTemplate
        MagicBean::CouponTemplate.where(id: params[:ids]).find_each do |coupon_template|
          coupon_template.toggle(:enabled).save
        end
        response_success
      end

      desc "订单赠品优惠券列表", {
        success: API::Entities::CouponTemplate,
        is_array: true
      }
      params do
        optional :created_at_gteq, type: Date, desc: "下单开始时间"
        optional :created_at_lteq, type: Date, desc: "下单结束时间"
      end
      paginate
      get "gift_coupons_data" do
        raise CanCan::AccessDenied unless current_user.permissions.include?("gift_coupons_analyses")

        blank_params_count = [params[:created_at_gteq], params[:created_at_lteq]].select(&:blank?).count
        return [] if blank_params_count == 2

        response_error("下单开始时间和结束时间必选") if blank_params_count > 0

        gifts_count = {}
        (MagicBean::Order.where.not(gift_coupon_template_id: nil).or(MagicBean::Order.where.not(pool_coupon_template_ids: nil))).paid.ransack(ransack_params).result.each do |order|
          if order.gift_coupon_template_id.present?
            gifts_count["#{order.gift_coupon_template_id}"] ||= 0
            gifts_count["#{order.gift_coupon_template_id}"] += 1
          end

          if order.pool_coupon_template_ids.present?
            order.pool_coupon_template_ids.each do |template_id|
              next if template_id.blank?
              gifts_count["#{template_id}"] ||= 0
              gifts_count["#{template_id}"] += 1
            end
          end
        end

        collection = MagicBean::CouponTemplate.where(id: gifts_count.keys).order(id: :desc)

        present paginate(collection), with: API::Entities::SimpleCouponTemplateWithGiftCount, gifts_count: gifts_count
      end

      route_param :id do
        helpers do
          def current_coupon_template
            @current_coupon_template ||= MagicBean::CouponTemplate.find params[:id]
          end
        end

        desc "优惠券模板详情", {
          success: API::Entities::CouponTemplate
        }
        get do
          authorize_and_response_resource
        end

        desc "更新优惠券模板", {
          success: API::Entities::CouponTemplate,
          skip_store_id: true
        }
        params do
          optional :all, using: API::Entities::CouponTemplate.documentation.dup.extract!(:enabled, :time_kind, :details_image, :remarks, :user_kind, :cost_accounting, :item_ids, :channel, :category_ids, :sub_category_ids, :brand_ids, :delivery_types, :payment_types, :assign_start_at, :assign_end_at, :assign_total_quantity)
        end
        put do
          params[:updated_by_admin] = true
          authorize_and_update_resource
        end

        desc "生成优惠券", {
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
          requires :quantity, type: Integer, positive_integer: true, desc: "数量"
        end
        post "generate_coupon" do
          authorize! :create, MagicBean::Coupon
          quantity = params[:quantity]
          response_error("数量不能大于5000") if quantity > 5000

          if resource.random_reduction? && quantity != resource.max_random_reduction_count
            response_error "请直接输入随机满减券数上限: #{resource.max_random_reduction_count}"
          end
          if resource.reach_max_random_reduction_count?(quantity)
            response_error "已达到/超过随机满减券数上限: #{resource.max_random_reduction_count}"
          end

          resource.generate_large_quantity_coupons(quantity, current_admin_user.id)
          #生成日志
          current_admin_user.operation_records.create(operatable: resource, content: "生成了 #{quantity} 张优惠券", store_id: resource.store_id)
          response_success
        end

        desc "批量分配优惠券", {
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
          requires :users_file, type: File, desc: "支持csv文件"
        end
        post "batch_assign_coupons" do
          response_error("请先补充 email 信息，不然没法接收通知结果") if current_admin_user.email.blank?
          response_error("随机满减优惠券不支持批量分配") if resource.random_reduction?
          response_error("请选择 csv 文件") unless check_file_type(params[:users_file], "csv")

          file_path = params[:users_file][:tempfile].path
          file_name = "coupon_templates/#{Date.current.strftime('%y%m%d')}/#{File.basename(file_path)}"

          file_url = aws_upload!(file_path, file_name)

          BatchAssignCouponsToUsersJob.perform_later(resource.id, file_url, current_admin_user.id)

          response_success
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
          response_error("已生成优惠券的模板不可导入产品") unless resource.can_edit?
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
      end
    end
  end
end
