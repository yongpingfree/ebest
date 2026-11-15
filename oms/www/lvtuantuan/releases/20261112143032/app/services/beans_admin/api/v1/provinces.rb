# frozen_string_literal: true

module BeansAdmin
  class API::V1::Provinces < ::API
    namespace :provinces, desc: "省份 API" do
      desc "省份列表", {
        success: API::Entities::Province,
        is_array: true
      }
      get do
        present MagicBean::Province.all, with: API::Entities::Province
      end
    end
  end
end
