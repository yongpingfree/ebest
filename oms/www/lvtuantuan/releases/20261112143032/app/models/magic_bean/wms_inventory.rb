# frozen_string_literal: true

module MagicBean
  class WmsInventory < ApplicationRecord
    # 只作为 WMS 临时存放数据用

    MAX_EXPIRATION_YEAR = 5.years # 假设商品最大保质期是 5 年

    scope :not_expired, -> { where(expiry_date: Date.today..MAX_EXPIRATION_YEAR.from_now) }
  end
end
