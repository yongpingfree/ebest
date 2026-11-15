# frozen_string_literal: true

module BeansAdmin
  class API::V1::QiniuMeta < ::API
    desc "获取七牛上传文件 token", {
      detail: <<-NOTES.strip_heredoc
        ```json
        {
          "token": "uptoken",
          "bucket_domain": "devcdn.beansmile-dev.com",
          "expires_in": 3600
        }
        ```
      NOTES
    }
    get "qiniu_meta" do
      present ::QiniuMeta.generate
    end
  end
end
