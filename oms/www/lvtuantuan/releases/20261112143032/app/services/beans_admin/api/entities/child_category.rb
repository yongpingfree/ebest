# frozen_string_literal: true

module BeansAdmin::API::Entities
  class ChildCategory < Category
    unexpose :children
  end
end
