# frozen_string_literal: true

module Wms::API::Entities
  class Store < Model
    expose :name
    expose :is_default
  end
end
