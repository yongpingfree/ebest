# frozen_string_literal: true
module MagicBean
  class Current < ActiveSupport::CurrentAttributes
    attribute :postal_code, :suburb, :store_id
  end
end
