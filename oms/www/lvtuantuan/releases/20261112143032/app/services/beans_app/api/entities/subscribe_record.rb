# frozen_string_literal: true

module BeansApp::API::Entities
  class SubscribeRecord < ::CommonEntities::Model
    expose :targetable_id, documentation: { desc: "targetable_id", type: Integer }
    expose :targetable_type, documentation: { desc: "targetable_type", type: String, values: MagicBean::SubscribeRecord::TARGETABLE_TYPES }
    expose :user_id, documentation: { desc: "user_id", type: Integer }
    expose :template_id, documentation: { desc: "template_id", type: String }
  end
end
