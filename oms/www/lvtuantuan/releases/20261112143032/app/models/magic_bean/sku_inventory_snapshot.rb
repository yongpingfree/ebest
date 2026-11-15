# frozen_string_literal: true
module MagicBean
  class SkuInventorySnapshot < ApplicationRecord
    belongs_to :stock_keeping_unit
  end
end
