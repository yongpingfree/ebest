require 'open-uri'
require 'mini_magick'
module Aliexpress::ImageBank
  @@logger = ::Logger.new("./log/aliexpress.log")
  class << self
    # aliexpress.photobank.redefining.getphotobankinfo
    def getphotobankinfo
      Aliexpress::Api.request_to_ae("aliexpress.photobank.redefining.getphotobankinfo", "POST", {}, top_client: true)
    end

    # aliexpress.image.redefining.uploadtempimageforsdk
    # file_data: 字符串形式的图片文件二进制数据流
    # 支持的图片格式：jpg, jpeg, gif
    def create(file_data, src_file_name: nil)
      Aliexpress::Api.request_to_ae("aliexpress.image.redefining.uploadtempimageforsdk", "POST", { file_data: file_data, src_file_name: src_file_name }, top_client: true)
    end

    def build(image_url)
      unless Validators::ResourceUrl.valid?(image_url)
        @@logger.error "invalid resource url, skip upload to aliexpress, image_url: #{image_url}"
        return
      end
      begin
        image = MiniMagick::Image.open(image_url)

        # 如果不是 jpg, jpeg, gif 格式的图片，转换为 jpg 格式
        unless %w(jpg jpeg gif).include?(image.type.downcase)
          image.format("jpg")
          image.write(image.path)
        end
      rescue => e
        @@logger.error "MiniMagick::Error: #{e}， image_url: #{image_url}"
        return
      end

      response = create(image.path, src_file_name: image.path.split("/").last)

      result = response.body.dig("result")
      if result&.dig("is_success")
        result.dig("url")
      end
    end
  end
end
