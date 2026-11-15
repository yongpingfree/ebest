# frozen_string_literal: true
module MagicBean
  class County < ApplicationRecord
    belongs_to :city

    enum kind: {
      system: 1,
      wechat: 2
    }
    after_commit :update_code, on: :create
    delegate :province, to: :city

    private

    def update_code
      c_index = province.cities.ids.sort.index(city.id)
      co_index = city.counties.ids.sort.index(id)
      self.code = province.id.to_s.rjust(2, "0") + (c_index + 1).to_s.rjust(2, "0") + (co_index + 1).to_s.rjust(2, "0")
      self.save
    end
  end
end
