# frozen_string_literal: true

class BatchUpdateShoplineInventoryJob < ApplicationJob
  queue_as :shopline
  include ::BeansAdmin::Helpers::FileUploadHelper

  def perform(*)
    # 只能同时有一个批量任务在执行，需要先判断是否有任务在执行
    current_bulk_operation = Shopline::Api.current_bulk_operation
    raise current_bulk_operation["errors"] if current_bulk_operation["errors"] && current_bulk_operation["errors"] != "no task"

    # 如果有任务在执行，且未完成，则不执行
    return if !current_bulk_operation["errors"] && current_bulk_operation["status"] != "COMPLETED" && current_bulk_operation["status"] != "FAILED"

    redis_key = Shopline::Api::INVENTORY_SKU_REDIS_KEY
    sku_count = Rails.cache.redis.llen(redis_key)
    # shopline要求file_url文件不能大于 10MB 并且文件的行数不能超过10000条，所以限制最多取5000条sku_id
    sku_ids = (1..[sku_count, 5000].min).map {|_| Rails.cache.redis.lpop(redis_key) }
    return if sku_ids.blank?
    
    # peti门店不需要批量更新
    sydney_url = "https://#{Shopline::Api::SYDNEY_HANDLE}.myshopline.com/admin/openapi/#{Shopline::Api::VERSION}/inventory_levels/set.json"
    location_ids = [Shopline::Api::SYDNEY_LOCATION_ID, Shopline::Api::SYDNEY_POST_LOCATION_ID]

    request_body = MagicBean::ThirdPartySku.includes([stock_keeping_unit: :item]).where(stock_keeping_unit_id: sku_ids).map do |t_sku|
      sku = t_sku.stock_keeping_unit
      item_delivery_type = sku.delivery_type
      inventory_item_id = t_sku.third_party_inventory_item_id

      location_ids.each_with_index.map do |location_id, index|
        next if location_id.blank?

        tmp_quantity = sku.quantity
        # index: 0为自派/自提，1为邮寄
        # 判断配送方式，来确认同步库存到哪个地点，不可同步则将库存设置为0
        tmp_quantity = 0 if index == 0 && (item_delivery_type & ["merchant_delivery", "self_pick"]).blank?
        tmp_quantity = 0 if index == 1 && item_delivery_type.exclude?("express")

        payload = {
          "available": tmp_quantity,
          "inventory_item_id": inventory_item_id,
          "location_id": location_id
        }

        {
          "url": sydney_url,
          "method": "post",
          "payload": payload
        }
      end
    end.flatten.compact

    file_path = Rails.root.join("public/shopline/batch_update_inventory_#{Time.current.to_i}.jsonl")
    dir = File.dirname(file_path)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    # 将request_body写入tmp/category.jsonl文件
    File.open(file_path, "w") do |f|
      request_body.each do |line|
        f.puts line.to_json
      end
    end

    file_name = "shopline/#{Date.current.strftime("%y%m%d")}/#{File.basename(file_path)}"
    aws_file_url = aws_upload!(file_path, file_name)

    File.delete(file_path) if File.exist?(file_path)
    # 一天后删除aws文件
    DeleteAwsFileJob.set(wait: 1.day).perform_later(aws_file_url)

    # 创建批量任务
    result = Shopline::Api.create_bulk_operation(aws_file_url)
    raise result["errors"] if result["errors"]
  end
end
