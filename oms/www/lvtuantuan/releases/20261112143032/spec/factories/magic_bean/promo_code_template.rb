# frozen_string_literal: true

FactoryBot.define do
  factory :promo_code_template, class: "MagicBean::PromoCodeTemplate" do
    title { "Promo Code" }
    enabled { true }
    start_on { Date.today }
    end_on { Date.tomorrow }

    store { MagicBean::Store.first || association(:store) }

    before(:create) do |pct|
      stock_keeping_unit = create(:stock_keeping_unit)
      pct.promo_stock_keeping_units_attributes = [{
        stock_keeping_unit_id: stock_keeping_unit.id,
        price_in_cent: 1,
        quantity: 1
      }]
    end
  end
end
