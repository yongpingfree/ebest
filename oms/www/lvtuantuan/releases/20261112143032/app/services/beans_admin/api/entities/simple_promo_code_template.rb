# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimplePromoCodeTemplate < ::CommonEntities::Model
    expose :title
    expose :enabled
    expose :display_in_item_detail
    expose :start_on
    expose :end_on
    expose :remark
    expose :can_edit?, as: :can_edit
    expose :user_kind
    expose :use_times_kind
    expose :purpose
  end
end
