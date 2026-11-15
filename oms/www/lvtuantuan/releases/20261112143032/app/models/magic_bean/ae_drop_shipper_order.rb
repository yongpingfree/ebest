# frozen_string_literal: true

class MagicBean::AeDropShipperOrder < ApplicationRecord
  belongs_to :order

  validates :ae_order_no, presence: true
  validates :ae_order_no, uniqueness: { scope: :order_id }
end
