# frozen_string_literal: true

module BeansApp::API::Entities
  class Groupon < SimpleGroupon
    expose :groupon_activity_price_range
    expose :item_price_range
    expose :item_title
    expose :groupon_activity_user_count
    expose :groupon_activity_rules
    expose :item, using: BeansApp::API::Entities::Item
  end
end
