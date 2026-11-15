# frozen_string_literal: true

Ransack.configure do |config|
  config.add_predicate "gteq_datetime",
    arel_predicate: "gteq",
    formatter: proc { |v| v.beginning_of_day },
    type: :date

  config.add_predicate "lteq_datetime",
    arel_predicate: "lteq",
    formatter: proc { |v| v.end_of_day },
    type: :date
end
