# frozen_string_literal: true

module Wms::API::Entities
  class Model < Grape::Entity
    expose :id, documentation: { type: Integer, desc: "id" }
    expose :updated_at, documentation: { type: DateTime, desc: "更新时间" }
    expose :created_at, documentation: { type: DateTime, desc: "创建时间" }
  end
end
