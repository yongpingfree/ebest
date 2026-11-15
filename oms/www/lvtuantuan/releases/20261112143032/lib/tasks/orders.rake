# frozen_string_literal: true

namespace :orders do
  desc "导出每日订单统计"
  task :export_by_date, [:email, :start_date, :end_date] => :environment do |t, args|
    start_date = args[:start_date].to_date
    end_date = args[:end_date].to_date
    email = args[:email]
    OrderMailer.analysis_by_date(email, start_date, end_date).deliver
  end
end
