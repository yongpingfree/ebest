# frozen_string_literal: true

class GenerateAwsLambdaImageJob < ApplicationJob
  queue_as :default

  def perform(class_name, id)
    # 只在生产环境运行
    return unless Rails.env.production?

    all_placeholder_images = false
    klass = class_name.constantize
    target = klass.find(id)

    return unless target

    case class_name.split("::").last
    when "Item"
      image_columns = %w(main_images detail_images cover share_cover)

      images = image_columns.map do |column|
        target.send(column)
      end.flatten.compact - [""]

      all_placeholder_images = images.present? && images.all? { |url| url.include?("zhanweitu") }

      results = images.map do |image|
        touch_aws_image_lambda(image)
      end

      if results.all?
        image_columns.each do |column|
          value = target.send(column)
          transfer_values = value.is_a?(Array) ? value.compact.map { |image| transfer_image_url(image) } : transfer_image_url(value)
          instance_variable_set("@#{column}", transfer_values)
        end

        target.update_columns(aws_lambda_image_generated: true, main_images: @main_images, detail_images: @detail_images, cover: @cover, share_cover: @share_cover)

        # 删除原图，images为一开始的原图url
        images.each do |image|
          delete_aws_image(image)
        end
      else
        target.update_columns(aws_lambda_image_generated: false)
      end
    when "StockKeepingUnit"
      original_image = target.image
      all_placeholder_images = original_image.present? && original_image.include?("zhanweitu")
      result = touch_aws_image_lambda(original_image)
      if result
        image = transfer_image_url(original_image)
        target.update_columns(aws_lambda_image_generated: true, image: image)
        delete_aws_image(original_image)
      else
        target.update_columns(aws_lambda_image_generated: false)
      end
    when "Category"
      images = [target.icon, target.filter_icon].compact
      all_placeholder_images = images.present? && images.all? { |url| url.include?("zhanweitu") }
      results = images.map do |image|
        touch_aws_image_lambda(image)
      end

      if results.all?
        icon = transfer_image_url(target.icon)
        filter_icon = transfer_image_url(target.filter_icon)
        target.update_columns(aws_lambda_image_generated: true, icon: icon, filter_icon: filter_icon)
        
        images.each do |image|
          delete_aws_image(image)
        end
      else
        target.update_columns(aws_lambda_image_generated: false)
      end
    when "Brand"
      original_cover = target.cover
      all_placeholder_images = original_cover.present? && original_cover.include?("zhanweitu")
      result = touch_aws_image_lambda(original_cover)
      if result
        cover = transfer_image_url(original_cover)
        target.update_columns(aws_lambda_image_generated: true, cover: cover)
        delete_aws_image(original_cover)
      else
        target.update_columns(aws_lambda_image_generated: false)
      end
    end

    # 如果所有图片都包含占位图，则不报错
    raise "生成缩略图失败" unless target.aws_lambda_image_generated || all_placeholder_images
  end

  def touch_aws_image_lambda(url)
    return false if url.include?("zhanweitu")
    return true if url.blank? || url.include?(AWS_THUMBNAIL_PREFIX_PATH)
    return false unless Validators::ResourceUrl.valid?(url)

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
    # 缩略图跳过删除，并且跳过删除占位图
    return if url.include?(AWS_THUMBNAIL_PREFIX_PATH) || url.include?("zhanweitu")

    Aws::CustomOss.delete_file(url)
  end
end
