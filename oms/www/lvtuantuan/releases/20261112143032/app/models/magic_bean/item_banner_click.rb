# frozen_string_literal: true

module MagicBean
  class ItemBannerClick < ApplicationRecord

    validates_uniqueness_of :date, scope: :item_banner_id

    belongs_to :item_banner
  end
end
