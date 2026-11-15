# frozen_string_literal: true

module BeansAdmin::API::Entities
  class PushMessage < SimplePushMessage
    expose :path_target_name
    expose :user_ids
    expose :users, using: BeansAdmin::API::Entities::User
    expose :item_id do |model, _options|
      model.path_customized_id if model.path_customized_type == "MagicBean::Item"
    end
    expose :custom_page_id do |model, _options|
      model.path_customized_id if model.path_customized_type == "MagicBean::CustomPage"
    end
    expose :custom_list_id do |model, _options|
      model.path_customized_id if model.path_customized_type == "MagicBean::CustomList"
    end
  end
end
