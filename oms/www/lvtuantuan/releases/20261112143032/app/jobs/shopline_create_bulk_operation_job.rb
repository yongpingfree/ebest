# frozen_string_literal: true

class ShoplineCreateBulkOperationJob < ApplicationJob
  queue_as :shopline

  def perform(aws_file_url)
    # 只能同时有一个批量任务在执行，需要先判断是否有任务在执行
    current_bulk_operation = Shopline::Api.current_bulk_operation
    raise current_bulk_operation["errors"] if current_bulk_operation["errors"] && current_bulk_operation["errors"] != "no task"

    # 如果有任务在执行，且未完成或未取消，则5分钟后再执行
    if !current_bulk_operation["errors"] && ["COMPLETED", "CANCELED"].exclude?(current_bulk_operation["status"])
      ShoplineCreateBulkOperationJob.set(wait: 5.minutes).perform_later(aws_file_url)
      return
    end

    # 创建批量任务
    result = Shopline::Api.create_bulk_operation(aws_file_url)
    raise result["errors"] if result["errors"]
  end
end
