# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Province < Grape::Entity
    expose :id, documentation: { type: Integer, desc: "ID" }
    expose :name, documentation: { desc: "省份名称" }
  end
end
