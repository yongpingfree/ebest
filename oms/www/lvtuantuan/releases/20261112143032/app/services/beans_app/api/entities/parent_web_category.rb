# frozen_string_literal: true

module BeansApp::API::Entities
  class ParentWebCategory < ::CommonEntities::Model
    expose :name, :status, :position, :icon, :bg_color, :display_length, :filter_icon
  end
end
