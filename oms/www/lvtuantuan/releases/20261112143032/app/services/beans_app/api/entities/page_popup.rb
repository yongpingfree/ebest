# frozen_string_literal: true

module BeansApp::API::Entities
  class PagePopup < ::CommonEntities::Model
    expose :title
    expose :image
    expose :format_path, as: :path
    expose :for_new_user
    expose :start_at
    expose :end_at
    expose :position
    expose :page_type
    expose :is_always, documentation: { type: Grape::API::Boolean, desc: "是否每次弹出" }
    expose :is_fullscreen, documentation: { type: Grape::API::Boolean, desc: "是否全屏" }
    expose :is_display, documentation: { type: Grape::API::Boolean, desc: "是否显示弹窗" }

    def format_path
      JSON.parse(object.path) if object.path?
    rescue JSON::ParserError
      nil
    end

    # 如果弹窗设置了au_suburb，则需要判断用户默认地址对应的au_suburb_id是不是在弹窗的au_suburb_ids中
    def is_display
      object.au_suburb_ids.blank? || object.au_suburb_ids.include?(options[:default_au_suburb_id])
    end
  end
end
