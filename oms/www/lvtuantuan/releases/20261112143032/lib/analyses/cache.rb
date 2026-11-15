# frozen_string_literal: true

module Analyses
  class Cache
    EXPIRE_PERIOD = 370.days

    def self.redis
      Rails.cache.redis
    end

    def self.key(name, date)
      "#{name}/#{date}"
    end

    def self.set(name, date, value)
      redis.set(key(name, date), value, ex: EXPIRE_PERIOD)
    end

    def self.incr(name, date)
      redis.incr(key(name, date))
      redis.expire(key(name, date), EXPIRE_PERIOD)
    end

    def self.get(name, date)
      redis.get(key(name, date))
    end
  end
end
