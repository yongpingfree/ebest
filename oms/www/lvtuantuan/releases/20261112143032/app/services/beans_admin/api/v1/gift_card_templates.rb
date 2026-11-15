# frozen_string_literal: true

module BeansAdmin
  class API::V1::GiftCardTemplates < ::API
    # 礼品券模板 API
    namespace :gift_card_templates, desc: "礼品券模板 API" do
      helpers BeansAdmin::Helpers::FileUploadHelper
      helpers do
        def default_order
          ["id desc"]
        end

        def permitted_params
          [:denominations_in_yuan, :denominations_in_cent, :quantity, :expired_at, :purchaser, :purpose, :not_eligible_for_free_gift, store_ids: []]
        end

        def valid_time?(timeString)
          begin
            return !!timeString.to_time
          rescue ArgumentError
            return false
          end
        end

        def end_of_association_chain
          store_ids = params[:store_id].present? ? [params[:store_id]] : "all"
          resource_class.store_ids_contains(store_ids)
        end
      end

      desc "礼品券模板列表", {
        success: API::Entities::GiftCardTemplate,
        skip_authentication: true
      }
      paginate
      get do
        stores_hash = {}
        MagicBean::Store.all.each do |store|
          stores_hash[store.id.to_s] = store.name
        end
        authorize_and_response_collection(present: { stores_hash: stores_hash })
      end

      desc "新增礼品券模板", {
        success: API::Entities::GiftCardTemplate
      }
      params do
        requires :all, using: API::Entities::GiftCardTemplate.documentation.dup.extract!(:denominations_in_yuan, :quantity, :expired_at, :purchaser, :purpose)
      end
      post do
        params[:store_ids] = [params[:store_id]] if params[:store_ids].blank? && params[:store_id].present?

        authorize_and_create_resource
      end

      desc "导入礼品券", {
        detail: <<-NOTES.strip_heredoc
          ```json
            errors: [
              {
                order_no: '',
                no: '',
                company: '',
                remark: '',
                message: ''
              }
            ]
          ```
        NOTES
      }
      params do
        requires :file_message, type: JSON, desc: "xlsx 文件信息"
      end
      post "import" do
        response_error("请选择 xlsx 文件") unless check_file_type(params[:file_message], "xlsx")

        table_header = { denominations_in_yuan: "金额", quantity: "数量", expired_at: "有效期", purchaser: "Purchaser", store_ids: "所属门店ID (多门店用；隔开，不填则默认全部门店)" }

        error_messages = []

        xlsx = Roo::Spreadsheet.open params[:file_message]["tempfile"].path
        result = xlsx.sheet(0).parse(table_header)

        MagicBean::GiftCardTemplate.transaction do
          result.each_with_index do |template, i|
            template[:store_ids] = (template[:store_ids].to_s.split(/[;；]/) || []).compact.map(&:strip).map(&:to_i) - [0]
            template[:store_ids] = MagicBean::Store.where(id: template[:store_ids]).ids if template[:store_ids].present?
            error = []
            error << "金额必须大于0" if template[:denominations_in_yuan].blank? || template[:denominations_in_yuan].to_i <= 0
            error << "数量必须大于0" if template[:quantity].blank? || template[:quantity].to_i <= 0
            error << "有效期格式不正确" unless valid_time?(template[:expired_at])
            error << "有效期格式不正确" if template[:purchaser].blank?
            if error.present?
              error_messages << "第#{i + 2}行: #{error.join(", ")}"
            else
              new_template = MagicBean::GiftCardTemplate.new(template)
              error_messages << "第#{i + 2}行: #{new_template.errors.full_messages.join("，")}" unless new_template.save
            end
          end
          raise if error_messages.present?
        end
        response_success
      rescue => _
        response_error(error_messages.join("; "))
      end

      route_param :id do
        desc "礼品券模板详情", {
          success: API::Entities::GiftCardTemplate
        }
        get do
          authorize_and_response_resource
        end
      end
    end
  end
end
