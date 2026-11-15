# frozen_string_literal: true
module MagicBean
  class ShareSetting < ApplicationRecord
    belongs_to :target, polymorphic: true
    belongs_to :store

    before_validation :set_store_id
    validate :check_search_columns

    private

    def set_store_id
      self.store_id = target.store_id if target.respond_to?(:store_id)
    end

    def check_search_columns
      errors.add(:base, "搜索关键词和搜索图标必须都填或都不填") if [search_words, search_cover].select(&:present?).count == 1
    end
  end
end
