# frozen_string_literal: true

class UpdateShoplineInventoryEveryDayJob < ApplicationJob
  queue_as :shopline
  include ::BeansAdmin::Helpers::FileUploadHelper

  def perform(*)
    return unless Rails.env.production?

    sydney_store = MagicBean::Store.sydney

    sydney_url = "https://#{Shopline::Api::SYDNEY_HANDLE}.myshopline.com/admin/openapi/#{Shopline::Api::VERSION}/inventory_levels/set.json"
    location_ids = [Shopline::Api::SYDNEY_LOCATION_ID, Shopline::Api::SYDNEY_POST_LOCATION_ID]

    # 每2000个sku批量更新一次
    current_index = 0
    MagicBean::ThirdPartySku.shopline.includes([stock_keeping_unit: :item]).ransack(stock_keeping_unit_store_id_eq: sydney_store.id).result.each_slice(2000) do |t_skus|
      current_index += 1

      request_body = t_skus.map do |t_sku|
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

      file_path = Rails.root.join("public/shopline/batch_update_inventory_#{Time.current.to_i}_#{current_index}.jsonl")
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

      # 每10分钟创建一次批量任务
      ShoplineCreateBulkOperationJob.set(wait: ((current_index - 1) * 10).minutes).perform_later(aws_file_url)
    end
  end
end
