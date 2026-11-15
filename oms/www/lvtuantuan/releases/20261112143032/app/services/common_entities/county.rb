# frozen_string_literal: true

module CommonEntities
  class County < Grape::Entity
    expose :id, documentation: { type: :integer }
    expose :name
  end
end
