# frozen_string_literal: true

json.array! @event_form_records do |record|
  json.call(record, :id, :data, :created_at, :updated_at)
end
