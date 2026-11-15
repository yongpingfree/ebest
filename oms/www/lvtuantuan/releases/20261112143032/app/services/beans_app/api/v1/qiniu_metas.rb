# frozen_string_literal: true

module BeansApp
  class API::V1::QiniuMetas < ::API
    desc "获取七牛上传文件 token", {
      detail: <<-NOTES.strip_heredoc
        ```json
        {
          "uptoken": "uptoken",
          "domain": "devcdn.beansmile-dev.com"
        }
        ```
      NOTES
    }
    get "qiniu_meta" do
      present ::QiniuMeta.generate
    end
  end
end
