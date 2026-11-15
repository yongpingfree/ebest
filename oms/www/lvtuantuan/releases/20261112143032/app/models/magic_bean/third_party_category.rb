# frozen_string_literal: true

class MagicBean::ThirdPartyCategory < ApplicationRecord

  enum third_party_type: { shopline: 1, aliexpress: 2 }

  belongs_to :category

  after_destroy :delete_shopline_product, if: -> { shopline? }

  def delete_shopline_product
    Shopline::Api.delete_category(third_party_id)
  end
end
