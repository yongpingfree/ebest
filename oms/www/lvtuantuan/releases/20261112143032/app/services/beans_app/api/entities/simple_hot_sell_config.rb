# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleHotSellConfig < ::CommonEntities::Model
    # App只需要显示分类
    expose :category_id
    expose :category_name
    expose :store_id
  end
end
