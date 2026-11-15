# frozen_string_literal: true

module QiniuUploadConcern
  extend ActiveSupport::Concern

  def qiniu_upload!(path)
    self.class.qiniu_upload!(path)
  end

  module ClassMethods
    def qiniu_upload!(path)
      meta = QiniuMeta.generate
      file = Pathname(path)
      code, result = Qiniu::Storage.upload_with_token_2(
        meta[:token],
        file,
        "images/#{Date.current.strftime("%y%m%d")}/#{SecureRandom.hex(5)[0..8]}",
        nil,
        bucket: meta[:bucket]
      )
      if code == 200
        file.delete
        "http://#{meta[:bucket_domain]}/#{result['key']}"
      else
        raise "Path[#{path}]: #{result[:error]}"
      end
    end
  end
end
