# frozen_string_literal: true

# 测试用例
  # img = Wechat::SecurityImgCheck.new("https://gxbl-staging.oss-cn-shenzhen.aliyuncs.com//images/vr_exhibition/d4070619-30ba-4d19-8a2d-ff6227bc79cc")
  # img.valid?
module Wechat
  class SecurityImgCheck < SecurityCheck
    include ActiveSupport::Callbacks
    define_callbacks :check

    set_callback :check, :before, :download_media
    set_callback :check, :after, :delete_tmp_file

    def initialize(media_url)
      @media_url = media_url
      @temp_path = nil
      @error = nil
    end

    def check
      run_callbacks :check do
        img_sec_check
      end
    end

    private
    def img_sec_check
      post(
        "/img_sec_check",
        body: {
          media: File.open(@temp_path)
        }
      )
    end

    def download_media
      raw = RestClient::Request.execute(method: :get, url: @media_url, raw_response: true)
      @temp_path = raw.file.path
    end

    def delete_tmp_file
      File.delete(@temp_path) if File.exist?(@temp_path)
    end
  end
end
