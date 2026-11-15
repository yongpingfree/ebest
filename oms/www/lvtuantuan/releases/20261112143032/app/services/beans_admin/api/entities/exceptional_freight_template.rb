# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ExceptionalFreightTemplate < SimpleDefaultFreightTemplate
    expose :freight_template_id, documentation: { type: "Integer" }
    expose :au_suburbs, using: BeansAdmin::API::Entities::AuSuburb
    expose :au_suburb_ids, documentation: { desc: "特殊地区ids" }
  end
end
