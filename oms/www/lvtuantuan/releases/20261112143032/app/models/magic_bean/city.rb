# frozen_string_literal: true
module MagicBean
  class City < ApplicationRecord
    belongs_to :province
    has_many :counties, dependent: :destroy

    enum kind: {
      system: 1,
      wechat: 2
    }

    after_commit :update_code, on: :create

    private

    def update_code
      c_index = province.cities.ids.sort.index(self.id)
      self.code = province.id.to_s.rjust(2, "0") + (c_index + 1).to_s.rjust(2, "0").ljust(4, "0")
      self.save
    end
  end
end
