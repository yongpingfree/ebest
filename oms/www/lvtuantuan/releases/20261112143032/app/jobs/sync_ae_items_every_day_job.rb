# frozen_string_literal: true

class SyncAeItemsEveryDayJob < ApplicationJob
  queue_as :aliexpress

  # 该job执行期间只记录warn以上的日志
  around_perform do |job, block|
    old_level = Rails.logger.level
    Rails.logger.level = Logger::WARN

    block.call
  ensure
    Rails.logger.level = old_level
  end 

  # 每天夜里比对新增消失的产品，消失的软删除，新增的创建
  # 每天中午比对消失的产品，软删除，中午不新增
  def perform(category_id = nil)
    return unless Rails.env.production?

    sync_at_night = Time.current.hour < 8
    
    category_ids = MagicBean::Category.where(ae_drop_shipper: true).top.order(id: :desc).ids
    
    # 避免job执行太长时间，内存一直占用，这里分批执行，每个category_id执行一次，及时释放内存
    current_category_id = category_id || category_ids.first
    next_category_id = category_ids.find { |id| id > current_category_id }
    parent_category = MagicBean::Category.find(current_category_id)
    
    # all_product_ids: 该分类AE最新所有的产品id
    # exists_product_ids: 该分类已保存到OMS的产品id
    # deleted_product_ids: 存在于OMS，但已被AE移除的产品id
    all_product_ids = get_category_product_ids(parent_category.ae_drop_shipper_category_id)
    exists_product_ids = MagicBean::Item.not_deleted.where(parent_category_id: parent_category.id, ae_drop_shipper: true).map { |product| product.no.to_i }
    new_product_ids = all_product_ids - exists_product_ids
    deleted_product_ids = exists_product_ids - all_product_ids
    # 有的产品分类变了，需要修改
    MagicBean::Item.not_deleted.where(ae_drop_shipper: true, no: new_product_ids).find_each(batch_size: 200) do |item|
      detail_response = Aliexpress::Api.get_dropshipper_product_detail(item.no)

      rsp_code = detail_response.body.dig("rsp_code")
      if rsp_code.in?(MagicBean::Item::AE_UNSALEABLE_CODE)
        next if item.pending? && item.ae_unsaleable
        item.ae_unsaleable_offline!
        MagicBean::OperationRecord.create(operatable: item, content: "同步下架不可销售AE产品，no: #{item.no}", store_id: item.store_id, channel: "admin")
        next
      end       

      product_result = detail_response.body.dig("result")
      item_info = product_result["ae_item_base_info_dto"]
      _, category_name = item_info["category_sequence"].split("/").first(2).map {|name| name.strip}
      category_id = item_info["category_id"]

      # AE的二级分类出现了很多相同名字但id不同的情况，所以需要用category_name来查询
      category = parent_category.children.ransack(translations_name_cont: category_name).result.first
      # 如果category不存在，则创建二级分类
      if category.blank?
        category_name_zh_cn = EasyTranslate.translate(category_name, from: :en, to: :"zh-CN")
        category = MagicBean::Category.create(
          name_zh_cn: category_name_zh_cn,
          name_en: category_name,
          ae_drop_shipper: true,
          parent_id: parent_category.id,
          ae_drop_shipper_category_id: category_id
        )
      end

      item.update_columns(parent_category_id: parent_category.id, category_id: category.id, ae_unsaleable: false)
    end

    if deleted_product_ids.present?
      offline_unsaleable_items(deleted_product_ids)
    end

    if sync_at_night
      new_product_ids.each do |product_id|
        MagicBean::Item.create_ae_item(product_id)
      end
    end

    SyncAeItemsEveryDayJob.perform_later(next_category_id) if next_category_id.present?
  end

  private
  def get_category_product_ids(category_id, search_id = "", current_product_ids = [])
    retry_times = 3
    begin
      response = Aliexpress::Api.get_dropshipper_product_ids(category_id, search_id)
      product_ids = response.body.dig("result", "products") || []
      return current_product_ids if product_ids.blank?
      
      current_product_ids += product_ids

      search_id = response.body.dig("result", "search_id")
      get_category_product_ids(category_id, search_id, current_product_ids) if search_id.present?
    rescue => e
      # 避免接口限制请求次数，这里休眠1s
      sleep(1)
      retry_times -= 1
      retry_times > 0 ? retry : current_product_ids
    end
  end

  def offline_unsaleable_items(product_ids)
    MagicBean::Item.where(ae_drop_shipper: true, no: product_ids).find_each do |item|
      item.ae_unsaleable_offline!
    end

    sydney_store = MagicBean::Store.sydney
    MagicBean::OperationRecord.create(content: "同步下架不可销售AE产品，no: #{product_ids.join(", ")}", store_id: sydney_store.id, channel: "admin")
  end
end
