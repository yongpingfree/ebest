# frozen_string_literal: true

module MagicBean
  class WebBanner < ApplicationRecord
    # scope

    # constants
    REDIS_KEY_NAMESPACE = "magic_bean/web_banner/".freeze

    # attr related macros
    enum page_location: {
      homepage_first: 1, # 首页第一个 banner（轮播图）
      homepage_second: 2, # 首页第二个 banner（每列 2 个的 banner）
      homepage_third: 3, # 首页第三个 banner（每列 3 个的 banner）
      popular_and_suggested: 4 # 首页商品分类上方的 2x2 排列 Popular & Suggested banner
    }

    # association macros
    belongs_to :store
    has_many :web_banner_items, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :web_banner
    accepts_nested_attributes_for :web_banner_items, allow_destroy: true

    # validation macros
    validates :page_location, presence: true, uniqueness: { scope: :store_id }
    validates :web_banner_items, presence: true, if: :displayed?
    validates :store_id, presence: true

    # callbacks
    after_commit :set_redis_hash

    # other macros
    ransacker :page_location, formatter: proc { |val| page_locations[val] }
    delegate :name, to: :store, prefix: true

    # class methods
    def self.of_store(target_store_id)
      JSON.parse(redis_hash(target_store_id).value) rescue {}
    end

    def self.redis_hash(target_store_id)
      redis_key = calculate_redis_key(target_store_id)
      Redis::Value.new(redis_key, compress: true)
    end

    def self.calculate_redis_key(target_store_id)
      "#{REDIS_KEY_NAMESPACE}-#{target_store_id}"
    end

    # instance methods
    def set_redis_hash
      rh = self.class.redis_hash(store_id)

      hash = {}
      self.class.where(store_id: store, displayed: true).find_each do |banner|
        hash[banner.page_location] = banner.web_banner_items
      end

      rh.value = hash.to_json

      hash
    end
  end
end
