# frozen_string_literal: true
module MagicBean
  class KuaidiCompanyMapping < ApplicationRecord
    validates :cn_name, presence: true, uniqueness: true
    validates :code, presence: true
  end
end
