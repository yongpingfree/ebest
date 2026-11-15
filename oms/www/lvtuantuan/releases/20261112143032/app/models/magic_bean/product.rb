# frozen_string_literal: true

class MagicBean::Product < ApplicationRecord
  has_many :items
  belongs_to :brand, optional: true
  belongs_to :category, optional: true
  belongs_to :minor_category, optional: true, class_name: "MagicBean::Category", foreign_key: "minor_category_id"
  belongs_to :store
  belongs_to :qa_and_guarantee, optional: true
  has_one :item, -> { left_joins(:product).where("items.store_id = products.store_id") }

  attr_accessor :import_skip_validation

  validates :brand, :category, :qa_and_guarantee, presence: true, if: -> { !import_skip_validation }

  delegate :name, to: :category, prefix: true, allow_nil: true
  delegate :name, to: :minor_category, prefix: true, allow_nil: true
  delegate :name, to: :brand, prefix: true, allow_nil: true
  delegate :name, to: :store, prefix: true, allow_nil: true
end
