# frozen_string_literal: true
module BeansAdmin::API::Entities
  class SimpleCustomPage < ::CommonEntities::Model
    expose :name
    expose :name_with_store
    expose :store_name
    expose :en_name
    expose :qrcode_url
    expose :bg_color
    expose :default
    expose :mini_program_path
    expose :share_setting, as: :share_setting_attributes
    expose :creator_id
    expose :creator_name
    expose :collaborator_ids
    expose :collaborators
    expose :app_share_url
  end
end
