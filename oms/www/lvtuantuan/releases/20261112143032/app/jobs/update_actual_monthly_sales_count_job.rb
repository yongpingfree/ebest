# frozen_string_literal: true

class UpdateActualMonthlySalesCountJob < ApplicationJob
  queue_as :default

  def perform
    `rake sidekiq:update_actual_monthly_sales_count_job`
  end
end
