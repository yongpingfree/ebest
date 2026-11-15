# frozen_string_literal: true

module BeansAdmin::API::Entities
  class MinimalItem < ::CommonEntities::Model
    translate_expose :title, documentation: { type: String, desc: "标题" }
    expose :short_title, documentation: { type: String, desc: "短标题" }
    expose :channels
    expose :delivery_type
    expose :cover
    expose :top_left_corner_tag_image
    expose :price_in_cent, documentation: { type: Integer, desc: "价格（分）" }
    expose :price_in_yuan
    expose :strikethrough_price_in_cent, documentation: { type: String, desc: "划线价格" }
    expose :strikethrough_price_in_yuan
    expose :same_day_delivery_title
    expose :show_expiration_date, documentation: { type: Grape::API::Boolean }
    expose :days_ahead_to_show_expiration, documentation: { type: Integer }
    expose :expiration_date
    expose :expiration_reminder_before_n_days, documentation: { type: Integer }

    def same_day_delivery_title
      object.same_day_delivery? ? "#{object.title}（当日达）" : object.title
    end
  end
end
