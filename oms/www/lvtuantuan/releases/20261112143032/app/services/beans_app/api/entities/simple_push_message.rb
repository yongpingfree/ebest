# frozen_string_literal: true

module BeansApp::API::Entities
  class SimplePushMessage < ::CommonEntities::Model
    expose :title
    expose :push_at
    expose :is_read
    expose :target_app_path
    expose :target_mini_program_path
    expose :content

    def is_read
      object.push_message_read_logs.map(&:user_id).include? current_user&.id
    end
  end
end
