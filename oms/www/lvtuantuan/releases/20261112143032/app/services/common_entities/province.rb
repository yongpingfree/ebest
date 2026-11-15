# frozen_string_literal: true

module CommonEntities
  class Province < Grape::Entity
    expose :id, documentation: { type: :integer }
    expose :name
    expose :cities, using: ::CommonEntities::City, documentation: { type: ::CommonEntities::City, is_array: true }
  end
end
