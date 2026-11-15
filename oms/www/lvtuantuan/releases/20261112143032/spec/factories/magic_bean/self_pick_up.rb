# frozen_string_literal: true

FactoryBot.define do
  factory :self_pick_up, class: "MagicBean::SelfPickUp" do
    name { "eBest自提点" }
    email { "service@ebest.com.au" }
    address { "457 Waterloo Rd" }
    mobile { "02 8985 2676‬" }
    google_place_id { "ChIJByzjrXe7EmsRcwQQ6fwBXpw" }
    province_name { "New South Wales" }
    city_name { "Greenacre" }
    street { "Waterloo Road" }
    street_number { "457" }
    postal_code { "2190" }
    latitude { -33.8903652 }
    longitude { 151.0615099 }
    opening_hours { "周一-周日12:00-18:00" }
    weekdays { %w(0 1 2 3 4 5 6) }
    time_period { ["12:00-18:00"] }
    store { MagicBean::Store.first || association(:store) }
  end
end
