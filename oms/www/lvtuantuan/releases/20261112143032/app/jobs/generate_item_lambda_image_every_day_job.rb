# frozen_string_literal: true

class GenerateItemLambdaImageEveryDayJob < ApplicationJob
  queue_as :default

  def perform
    # 只在生产环境运行
    return unless Rails.env.production?

    MagicBean::Item.where(aws_lambda_image_generated: false, ae_drop_shipper: false).find_each do |item|
      item.send :enqueue_generate_aws_lambda_image_job
    end
  end
end
