# frozen_string_literal: true

module BeansApp::API::Entities
  class PublicLotteryWinningUser < ::CommonEntities::Model
    expose :user_id
    expose :user_fuzzy_name
  end
end
