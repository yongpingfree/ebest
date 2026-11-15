# frozen_string_literal: true

class MagicBean::DeliveryTimeOrderDateAnalysis < ApplicationRecord
  validates_uniqueness_of :delivery_date, scope: :delivery_time_id
  validates_presence_of :delivery_date, :delivery_time_id, :distinct_address_count
end
