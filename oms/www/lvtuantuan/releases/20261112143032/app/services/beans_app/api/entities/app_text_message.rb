# frozen_string_literal: true

module BeansApp::API::Entities
  class AppTextMessage < ::CommonEntities::Model
    expose :title, documentation: { type: String, desc: "标题" }
    expose :content, documentation: { type: String, desc: "内容" }
    expose :is_read, documentation: { type: Grape::API::Boolean, desc: "是否已读" }
    expose :push_at, documentation: { desc: "发布时间" }
    expose :kind
    expose :target_mini_program_path
    expose :target_app_path
  end
end
