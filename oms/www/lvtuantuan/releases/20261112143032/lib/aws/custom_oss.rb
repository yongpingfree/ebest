# frozen_string_literal: true

module Aws
  class CustomOss
    def self.delete_file(file_url)
      file_key = URI(file_url).path[1..-1]
      bucket_name = AWS_SETTING[:bucket]
      s3 = Aws::S3::Resource.new
      obj = s3.bucket(bucket_name).object(file_key)
      obj.delete
    end
  end
end
