# frozen_string_literal: true

module BeansAdmin::API::Entities
  class DefaultFreightTemplate < SimpleDefaultFreightTemplate
    expose :exceptional_freight_templates, using: BeansAdmin::API::Entities::ExceptionalFreightTemplate, as: :exceptional_freight_templates_attributes
  end
end
