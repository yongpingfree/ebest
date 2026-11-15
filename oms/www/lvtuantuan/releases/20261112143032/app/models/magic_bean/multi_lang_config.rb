# frozen_string_literal: true

# key -> name 对照表查看 docs/multi_lang_config_mappings.md 文件
module MagicBean
  class MultiLangConfig < ApplicationRecord
    # constants
    REDIS_KEY_NAMESPACE = "magic_bean/multi_lang_configs/".freeze

    # concerns

    # attr related macros
    enum kind: { app: 0, admin: 1 }
    ransacker :kind, formatter: proc { |val| kinds[val] }

    # association macros
    belongs_to :store, optional: true

    # validation macros
    validates :key, presence: true
    validates :name, presence: true
    validates :kind, presence: true

    # callbacks
    after_commit :reset_redis_config

    # other macros
    translates :value
    globalize_accessors attributes: [:value]

    delegate :name, to: :store, prefix: true, allow_nil: true

    # scopes

    # class methods
    def self.config(store_id, locale, kind)
      rc = redis_config(store_id, locale, kind)

      if rc.value.nil?
        hash = {}

        # 管理后台的 I18n.locale 一直是 :"zh-CN"，需要手动更改，然后再还原
        if kind.to_s == "admin"
          original_locale = I18n.locale
          I18n.locale = locale
        end

        self.includes(:translations).where(store_id: [nil, store_id], kind: kind).find_each do |record|
          hash[record.key] = record.value
        end

        I18n.locale = original_locale if kind.to_s == "admin"

        rc.value = hash.to_json
      end

      JSON.parse(rc.value, object_class: OpenStruct)
    end

    # instance methods

    private

    def self.redis_config(store_id, locale, kind)
      redis_key = calculate_redis_key(store_id, locale, kind.to_s)
      Redis::Value.new(redis_key, compress: true)
    end

    def self.calculate_redis_key(store_id, locale, kind)
      "#{REDIS_KEY_NAMESPACE}-#{store_id}-#{locale}-#{kind}"
    end

    def reset_redis_config
      if store_id.blank?
        Redis::Objects.redis.keys("#{REDIS_KEY_NAMESPACE}*").each do |key|
          Redis::Value.new(key).clear
        end
      else
        I18n.available_locales.each do |locale|
          self.class.redis_config(store_id, locale, kind).clear
        end
      end
    end
  end
end
