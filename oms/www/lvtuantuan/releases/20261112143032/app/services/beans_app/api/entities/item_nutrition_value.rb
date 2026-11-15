# frozen_string_literal: true

module BeansApp::API::Entities
  class ItemNutritionValue < ::CommonEntities::Model
    expose :nutrition_name
    expose :avg_qty_per_package
    expose :avg_qty_per_100_units
  end
end
