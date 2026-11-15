# frozen_string_literal: true

class MagicBean::ThirdPartySku < ApplicationRecord

  enum third_party_type: { shopline: 1, aliexpress: 2 }

  belongs_to :stock_keeping_unit
end
