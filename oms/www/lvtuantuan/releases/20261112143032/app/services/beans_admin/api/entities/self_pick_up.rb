# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SelfPickUp < ::CommonEntities::Model
    expose :name, documentation: { type: String, desc: "自提点名称" }
    expose :mobile, documentation: { type: String, desc: "联系方式" }
    expose :email, documentation: { type: String, desc: "邮箱" }
    expose :address, documentation: { type: String, desc: "地址" }
    expose :province_name, documentation: { type: String, desc: "省份" }
    expose :city_name, documentation: { type: String, desc: "城市" }
    expose :google_place_id, documentation: { type: String, desc: "地址GooglePlace ID" }
    expose :opening_hours, documentation: { type: String, desc: "营业时间" }
    expose :latitude, documentation: { type: Float, desc: "纬度" }
    expose :longitude, documentation: { type: Float, desc: "经度" }
    expose :postal_code, documentation: { type: String, desc: "邮编" }
    expose :street, documentation: { type: String, desc: "街道" }
    expose :street_number, documentation: { type: String, desc: "门牌号" }
    expose :self_pick_orders_limit_every_day, documentation: { type: Integer, desc: "自提点每日自提限额" }
    expose :weekdays
    expose :time_period
    expose :enabled
    expose :support_same_day_delivery
  end
end
