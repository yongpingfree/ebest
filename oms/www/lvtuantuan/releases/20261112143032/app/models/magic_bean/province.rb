# frozen_string_literal: true
module MagicBean
  class Province < ApplicationRecord
    has_many :cities, dependent: :destroy

    enum kind: {
      system: 1,
      wechat: 2
    }

    after_commit :update_code, on: :create

    private

    def update_code
      self.code = id.to_s.rjust(2, "0").ljust(6, "0")
      self.save
    end
  end
end
