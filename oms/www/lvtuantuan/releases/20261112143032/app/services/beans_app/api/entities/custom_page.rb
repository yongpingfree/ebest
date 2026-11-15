# frozen_string_literal: true
module BeansApp::API::Entities
  class CustomPage < ::CommonEntities::Model
    expose :name
    expose :en_name
    expose :qrcode_url
    expose :components
    expose :bg_color
    expose :default
    expose :share_setting
  end
end
