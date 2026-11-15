# frozen_string_literal: true

module MagicBean
  class SkuValidInventoryDate < ApplicationRecord
    belongs_to :stock_keeping_unit

    validates :date, presence: true
    validates :date, uniqueness: { scope: :stock_keeping_unit_id }
  end
end
