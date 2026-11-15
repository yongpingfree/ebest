# frozen_string_literal: true

module BeansApp::API::Entities
  class Address < ::CommonEntities::Model
    expose :detail_info, documentation: { type: String, desc: "详细地址" }
    expose :postal_code, documentation: { type: String, desc: "邮政编码" }
    expose :tel_number, documentation: { type: String, desc: "手机" } do |object|
      object.tel_number.first(2) == "61" ? object.tel_number[2..-1] : object.tel_number
    end
    expose :google_place_id, documentation: { type: String, desc: "谷歌地址ID，GooglePlace的 place_id" }
    expose :province_name, documentation: { type: String, desc: "省份名" }
    expose :city_name, documentation: { type: String, desc: "城市名" }
    expose :is_default, documentation: { type: Grape::API::Boolean, desc: "默认地址" }
    expose :email, documentation: { type: String, desc: "邮箱" }
    expose :street, documentation: { type: String, desc: "街道" }
    expose :street_number, documentation: { type: String, desc: "门牌号" }
    expose :company_name, documentation: { type: String, desc: "公司名" }
    expose :alias_name, documentation: { type: String, desc: "地址名称" }
    expose :first_name, documentation: { type: String, desc: "接收者名字" }
    expose :last_name, documentation: { type: String, desc: "接收者名字" }
    expose :unit_number, documentation: { type: String, desc: "unit number" }
    expose :human_address
    expose :remark, documentation: { type: String, desc: "备注" }
    expose :housing_type, documentation: { type: String, desc: "住宅类型" }
  end
end
