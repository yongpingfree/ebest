# frozen_string_literal: true

class MagicBean::ThirdPartyItem < ApplicationRecord

  enum third_party_type: { shopline: 1, aliexpress: 2 }

  belongs_to :item

  after_destroy :archived_shopline_product, if: -> { shopline? }

  def archived_shopline_product
    # FIXME: 这里要改为异步处理
    Shopline::Api.update_product(item, third_party_id, true)
  end
end
