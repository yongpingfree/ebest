# frozen_string_literal: true
module BeansAdmin::API::Entities
  class PageLink < Grape::Entity
    expose :custom_name, as: :name
    expose :path

    def path
      { link: "/#{object.mini_program_path}", app_link: "#{object.app_path}" }
    end

    def custom_name
      if object.class == MagicBean::CouponTemplate
        object.title_with_store
      elsif object.class == MagicBean::CustomList
        object.same_day_delivery_title
      elsif object.class == MagicBean::HotSellConfig
        "热卖榜-#{object.category.name}"
      else
        object.name
      end
    end
  end
end
