# frozen_string_literal: true

module BeansAdmin::API::Entities
  class FormItem < SimpleFormItem
    translate_expose :description, documentation: { type: String, desc: "描述" }
    expose :form_options
    expose :notification_emails
    expose :main_images, documentation: { type: Array[String], desc: "商品主图链接列表", documentation: { param_type: "body" } }
    expose :detail_images, documentation: { type: Array[String], desc: "商品详情图链接列表", documentation: { param_type: "body" } }
    translate_expose :name_placeholder, documentation: { type: String, desc: "姓名占位符" }
    translate_expose :mobile_placeholder, documentation: { type: String, desc: "手机号占位符" }
    translate_expose :email_placeholder, documentation: { type: String, desc: "邮箱占位符" }
    translate_expose :birthday_placeholder, documentation: { type: String, desc: "生日占位符" }
    translate_expose :address_placeholder, documentation: { type: String, desc: "地址占位符" }
    translate_expose :remark_placeholder, documentation: { type: String, desc: "备注占位符" }
  end
end
