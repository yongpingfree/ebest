# frozen_string_literal: true

module BeansApp::API::Entities
  class CouponTemplate < ::CommonEntities::Model
    expose :title, documentation: { desc: "名字" }
    expose :desc, documentation: { desc: "说明" }
    expose :details_image, documentation: { desc: "详情页封面" }
    expose :code, documentation: { desc: "代码" }
    expose :user_kind
    expose :target_kind, documentation: { desc: "作用类型" }
    expose :channel, documentation: { type: String, values: ->() { MagicBean::CouponTemplate.channels.keys }, desc: "平台类型" }
    expose :kind
    expose :denominations_in_cent
    expose :denominations_in_yuan
    expose :at_least_amount_in_cent
    expose :at_least_amount_in_yuan
    expose :need_at_least_amount
    expose :discount
    expose :start_at
    expose :end_at
    expose :expired_at
    expose :site_setting_type

    def site_setting_type
      if current_store_site_config&.newbie_coupon_template_ids&.include? object.id
        "newbie"
      elsif current_store_site_config&.invited_coupon_template_ids&.include?(object.id)
        "invited"
      end
    end

    def current_store_site_config
      @current_store_site_config ||= MagicBean::SiteConfig.find_by store_id: current_store_id
    end
  end
end
