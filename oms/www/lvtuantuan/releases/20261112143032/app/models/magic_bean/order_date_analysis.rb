# frozen_string_literal: true

class MagicBean::OrderDateAnalysis < ApplicationRecord
  validates_uniqueness_of :delivery_date, scope: :store_id
  validates_presence_of :delivery_date, :store_id, :distinct_address_count
end
