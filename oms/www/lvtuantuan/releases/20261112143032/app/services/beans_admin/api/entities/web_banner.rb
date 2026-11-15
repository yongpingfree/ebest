# frozen_string_literal: true

module BeansAdmin::API::Entities
  class WebBanner < SimpleWebBanner
    expose :web_banner_items, using: WebBannerItem
  end
end
