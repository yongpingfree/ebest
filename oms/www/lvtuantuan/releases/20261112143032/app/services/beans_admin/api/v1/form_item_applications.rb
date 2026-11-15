# frozen_string_literal: true

module BeansAdmin
  class API::V1::FormItemApplications < ::API

    namespace :form_item_applications, desc: "表格商品申请 API" do
      helpers do
        def includes
          [:store, form_item: :translations]
        end

        def default_order
          ["created_at DESC"]
        end
      end

      desc "表格商品列表", {
        success: API::Entities::FormItemApplication,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "导出表格商品列表"
      get "export" do
        authorize! :read, resource_class

        filename = "form-item-application-#{Date.current.strftime('%Y-%m-%d')}.xlsx"

        package = Axlsx::Package.new do |pkg|
          headers = %w[编号 表格产品 门店 平台 姓名 邮箱 电话 生日 地址]
          types = %i[integer string string string string string string string string]

          pkg.workbook.add_worksheet do |sheet|
            sheet.add_row headers

            collection.each do |application|
              row = [application.id, application.form_item.title, application.store.name, application.channel, application.apply_name, application.apply_email, application.apply_mobile, application.apply_birthday, application.apply_address]
              sheet.add_row(row, types: types)
            end
          end
        end

        content_type "application/octet-stream"
        header["Content-Disposition"] = "attachment; filename=#{filename}"
        env["api.format"] = :binary

        package.to_stream.read
      end
    end
  end
end
