# frozen_string_literal: true

class MagicBean::SelfPickOrderDateAnalysis < ApplicationRecord
  validates_uniqueness_of :delivery_date, scope: :self_pick_up_id
  validates_presence_of :delivery_date, :self_pick_up_id, :orders_count
end
