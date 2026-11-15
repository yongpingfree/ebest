# frozen_string_literal: true

module BeansApp
  class API::V1::FormItems < ::API
    namespace :form_items, desc: "创建评论" do
      helpers do
        def includes
          [:translations]
        end

        def generate_apply_properties
          options_errors = []
          apply_properties = {}
          resource.form_options.each do |opt|
            apply_properties[opt] = params[opt]
            options_errors << I18n.t("grape.form_items.form_option_cannot_be_empty", form_option: I18n.t("grape.form_items.form_options.#{opt}")) if params[opt].blank?
          end

          response_error(options_errors.join("，")) if options_errors.present?

          apply_properties
        end
      end

      desc "表格商品列表", {
        success: API::Entities::SimpleFormItem,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        optional :order_by, type: String
        optional :keyword, types: [String, Array], desc: "搜索商品标题、描述，多个关键字用空格分割", coerce_with: ->(val) { val.to_s.split(" ") }
        optional :category_id_eq, type: Integer, desc: "产品分类ID", as: :minor_category_id_or_category_id_eq
        optional :category_id_in, type: Array[Integer], coerce_with: ->(val) { val.to_s.split(",").map(&:to_i) }, desc: "产品二级分类 ids", as: :minor_category_id_or_category_id_in
        optional :category_parent_id_in, type: Array[Integer], coerce_with: ->(val) { val.to_s.split(",").map(&:to_i) }, desc: "产品一级分类ids", as: :minor_category_parent_id_or_category_parent_id_in
        optional :category_parent_id_eq, type: Integer, desc: "一级分类ID", as: :minor_category_parent_id_or_category_parent_id_eq
      end
      get do
        @collection = MagicBean::FormItem.includes(includes).online.send("#{ebest_channel}_channel")
        params[:store_id_eq] = current_store_id
        params.delete(:minor_category_parent_id_or_category_parent_id_eq) if params[:minor_category_id_or_category_id_eq].present? && params[:minor_category_parent_id_or_category_parent_id_eq].present?

        # 如果只传了一级分类，需要把隐藏的二级分类对应的商品过滤掉（只隐藏主分类的子分类的商品）
        if params[:minor_category_parent_id_or_category_parent_id_eq].present?
          parent_category = MagicBean::Category.find_by(id: params[:minor_category_parent_id_or_category_parent_id_eq])
          if parent_category
            children_ids = parent_category.children.hidden.ids
            params[:category_id_not_in] = children_ids if children_ids.present?
          end
        end

        @collection = @collection.accessible_by(current_ability).includes(includes).ransack(ransack_params)

        if params[:order_by].present?
          order_by = (params[:order_by].split(",").map(&:strip).compact + default_order).uniq
          @collection.sorts = order_by
        end

        @collection =
          if params[:keyword].present?
            keyword_match_order_sql = ""
            params[:keyword].each_with_index do |keyword, index|
              keyword_match_order_sql += " + " unless index.zero?
              keyword = keyword.gsub("'", "''")
              keyword_match_order_sql += "(case when POSITION('#{keyword&.downcase}' IN lower(translated_searchable_title)) > 0 then 1 else 0 end)"
            end
            keyword_match_order_sql = "sum(#{keyword_match_order_sql})"
            form_items = @collection.result.select("form_items.*, #{keyword_match_order_sql} as cnt")

            if params[:order_by].blank?
              form_items.reorder("cnt desc, form_items.created_at DESC")
            else
              form_items
            end.group(:id)
          else
            @collection.result
          end

        response_collection
      end

      route_param :id do
        desc "商品详情", {
          success: API::Entities::FormItem,
          skip_authentication: true
        }
        get do
          present resource, with: API::Entities::FormItem
        end

        desc "填写表格", {
          success: API::Entities::FormItem
        }
        params do
          optional :name, type: String, desc: "姓名"
          optional :mobile, type: String, desc: "手机"
          optional :email, type: String, desc: "Email"
          optional :birthday, type: String, desc: "生日"
          optional :address, type: String, desc: "地址"
          optional :remark, type: String, desc: "备注"
        end
        post "apply" do
          apply_properties = generate_apply_properties

          application = resource.form_item_applications.new(
            user: current_user,
            apply_properties: apply_properties,
            store_id: current_store_id,
            channel: ebest_channel
            )

          if application.save
            response_success
          else
            response_record_error(application)
          end
        end
      end
    end
  end
end
