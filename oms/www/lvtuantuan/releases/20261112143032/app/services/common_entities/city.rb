# frozen_string_literal: true

module CommonEntities
  class City < Grape::Entity
    expose :id, documentation: { type: :integer }
    expose :name
    expose :counties, using: ::CommonEntities::County, documentation: { type: ::CommonEntities::County, is_array: true }
  end
end
