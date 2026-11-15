# frozen_string_literal: true

module BeansApp::API::Entities
  class FormItem < SimpleFormItem
    expose :form_options
    expose :main_images, documentation: { type: Array[String], desc: "商品主图链接列表", documentation: { param_type: "body" } }
    expose :detail_images, documentation: { type: Array[String], desc: "商品详情图链接列表", documentation: { param_type: "body" } }
    # expose _placeholder结尾的字段
    expose :name_placeholder, documentation: { type: String, desc: "姓名占位符" }
    expose :mobile_placeholder, documentation: { type: String, desc: "手机号占位符" }
    expose :email_placeholder, documentation: { type: String, desc: "邮箱占位符" }
    expose :birthday_placeholder, documentation: { type: String, desc: "生日占位符" }
    expose :address_placeholder, documentation: { type: String, desc: "地址占位符" }
    expose :remark_placeholder, documentation: { type: String, desc: "备注占位符" }
  end
end
