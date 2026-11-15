# frozen_string_literal: true

module BeansAdmin::API::Entities
  class EventPage < ::CommonEntities::Model
    expose :name
    expose :event_form_records_count
    expose :users_count
  end
end
