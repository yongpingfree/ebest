# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ChildWebCategory < WebCategory
    unexpose :children
  end
end
