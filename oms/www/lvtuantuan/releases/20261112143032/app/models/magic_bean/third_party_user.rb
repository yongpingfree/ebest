# frozen_string_literal: true

module MagicBean
  class ThirdPartyUser < ApplicationRecord
    enum third_party_type: { shopline: 1, aliexpress: 2 }
    
    validates :third_party_id, presence: true, uniqueness: { scope: :third_party_type }

    belongs_to :store

    delegate :peti_store?, to: :store
  end  
end
