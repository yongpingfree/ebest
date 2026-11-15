# frozen_string_literal: true

namespace :aws do
  
  desc "触发lambda生成缩略水印图"
  task touch_lambda_images: :environment do |t, args|
    MagicBean::Item.where(aws_lambda_image_generated: false).find_each do |item|
      images = item.main_images + item.detail_images + [item.cover, item.share_cover]
      
      results = (images.compact - [""]).map do |image|
        touch_aws_image_lambda(image)
      end

      if results.all?
        item.update_columns(aws_lambda_image_generated: true) 
      end
    end

    MagicBean::StockKeepingUnit.where(aws_lambda_image_generated: false).find_each do |sku|
      next if sku.image.blank?
      result = touch_aws_image_lambda(sku.image)
      if result
        sku.update_columns(aws_lambda_image_generated: true)
      end
    end

    MagicBean::Brand.where(aws_lambda_image_generated: false).find_each do |brand|
      next if brand.cover.blank?
      result = touch_aws_image_lambda(brand.cover)
      brand.update_columns(aws_lambda_image_generated: true) if result
    end

    MagicBean::Category.where(aws_lambda_image_generated: false).find_each do |category|
      results = ([category.icon, category.filter_icon].compact - [""]).map do |image|
        touch_aws_image_lambda(image)
      end
  
      category.update_columns(aws_lambda_image_generated: true) if results.all?
    end

    # 处理OrderItem图片
    error_order_item_images = []
    MagicBean::OrderItem.ransack(image_not_cont: AWS_THUMBNAIL_PREFIX_PATH).result.group(:image).count.keys.each do |image|
      result = touch_aws_image_lambda(image)
      error_order_item_images << image unless result
    end

    puts error_order_item_images

    error_gifts_orders = []
    # order的gifts_properties和pool_gifts_properties图片包含了原图
    MagicBean::Order.where.not(gifts_properties: nil).find_each do |order|
      gifts_properties = order.gifts_properties
      next if gifts_properties.blank?
      count = 0
      results = gifts_properties.map do |gift|
        url = gift["image"]
        next if url.blank?
        result = touch_aws_image_lambda(url)
        # 将图片路径中的AWS_CDN_HOST替换为AWS_THUMBNAIL_PREFIX_PATH
        if url.exclude?(AWS_THUMBNAIL_PREFIX_PATH)
          gift["image"] = url.gsub(AWS_CDN_HOST, AWS_THUMBNAIL_PREFIX_PATH)
          count += 1
        end

        result
      end

      next if count.zero?

      if results.all?
        order.update_columns(gifts_properties: gifts_properties)
      else
        error_gifts_orders << order.id
      end
    end

    error_pool_gifts_orders = []
    MagicBean::Order.where.not(pool_gifts_properties: nil).find_each do |order|
      pool_gifts_properties = order.pool_gifts_properties
      next if pool_gifts_properties.blank?
      count = 0
      results = pool_gifts_properties.map do |gift|
        url = gift["image"]
        next if url.blank?
        result = touch_aws_image_lambda(url)
        # 将图片路径中的AWS_CDN_HOST替换为AWS_THUMBNAIL_PREFIX_PATH
        if url.exclude?(AWS_THUMBNAIL_PREFIX_PATH)
          gift["image"] = url.gsub(AWS_CDN_HOST, AWS_THUMBNAIL_PREFIX_PATH)
          count += 1
        end
        result
      end

      next if count.zero?

      if results.all?
        order.update_columns(pool_gifts_properties: pool_gifts_properties)
      else
        error_pool_gifts_orders << order.id
      end
    end
  end

  desc "删除已经生成缩略水印图的原图"
  task delete_original_images: :environment do |t, args|
    MagicBean::Item.where(aws_lambda_image_generated: true).find_each do |item|
      images = item.main_images + item.detail_images + [item.cover, item.share_cover]
      
      (images.compact - [""]).each do |image|
        delete_aws_image(image)
      end
    end

    MagicBean::StockKeepingUnit.where(aws_lambda_image_generated: true).find_each do |sku|
      next if sku.image.blank?
      delete_aws_image(sku.image)
    end

    MagicBean::Brand.where(aws_lambda_image_generated: true).find_each do |brand|
      next if brand.cover.blank?
      delete_aws_image(brand.cover)
    end

    MagicBean::Category.where(aws_lambda_image_generated: true).find_each do |category|
      ([category.icon, category.filter_icon].compact - [""]).each do |image|
        delete_aws_image(image)
      end
    end
  end

  desc "产品跳过部分图片生成水印图"
  task touch_lambda_images_skip_failed: :environment do |t, args|
    # 有个别图片生成水印图失败，但不想影响其他图片生成，所以跳过这些图片
    MagicBean::Item.where(aws_lambda_image_generated: false, ae_drop_shipper: false).each do |item|
      new_main_images = item.main_images.map do |image|
        touch_aws_image_lambda(image) ? transfer_image_url(image) : image
      end

      new_detail_images = item.detail_images.map do |image|
        touch_aws_image_lambda(image) ? transfer_image_url(image) : image
      end

      new_cover = touch_aws_image_lambda(item.cover) ? transfer_image_url(item.cover) : item.cover
      new_share_cover = touch_aws_image_lambda(item.share_cover) ? transfer_image_url(item.share_cover) : item.share_cover

      item.update_columns(aws_lambda_image_generated: true, main_images: new_main_images, detail_images: new_detail_images, cover: new_cover, share_cover: new_share_cover)
    end
  end

  def touch_aws_image_lambda(url)
    return true if url.blank? || url.include?(AWS_THUMBNAIL_PREFIX_PATH)
    tmp_url = url.gsub(AWS_CDN_HOST, AWS_THUMBNAIL_PREFIX_PATH)
    retry_times = 3
    
    begin
      RestClient.get(tmp_url)
      true
    rescue => e
      retry_times -= 1
      retry_times > 0 ? retry : false
    end
  end

  def transfer_image_url(url)
    return url if url.blank?
    url.include?(AWS_THUMBNAIL_PREFIX_PATH) ? url : url.gsub(AWS_CDN_HOST, AWS_THUMBNAIL_PREFIX_PATH)
  end

  def delete_aws_image(url)
    return if url.blank?
    # 该方法是提供给已经生成缩略图的url删除原图, 如果url不是缩略图url, 则跳过删除
    return unless url.include?(AWS_THUMBNAIL_PREFIX_PATH)
    
    # 占位图跳过删除
    return if url.include?("zhanweitu")

    # 需要把缩略图url转换为原图url
    Aws::CustomOss.delete_file(url.gsub(AWS_THUMBNAIL_PREFIX_PATH, AWS_CDN_HOST))
  end
end
