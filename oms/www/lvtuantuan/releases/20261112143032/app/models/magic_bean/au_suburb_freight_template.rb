# frozen_string_literal: true
module MagicBean
  class AuSuburbFreightTemplate < ApplicationRecord
    belongs_to :au_suburb
    belongs_to :freight_template
  end
end
