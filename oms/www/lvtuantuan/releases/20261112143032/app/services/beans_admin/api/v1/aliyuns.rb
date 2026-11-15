# frozen_string_literal: true

module BeansAdmin
  class API::V1::Aliyuns < ::API
    namespace :aliyun, desc: "阿里云" do
      desc "获取阿里云签名", detail: <<-NOTES.strip_heredoc
        返回签名

        ```json
        {
          "access_key_id": "LTAIhXi3MQWUfzw1",
          "host": "http://gxbl-staging.oss-cn-shenzhen.aliyuncs.com",
          "policy": "eyJleHBpcmF0aW9uIjoiMjAxOC0wMy0xNlQwMzozMDozNS4wMDBaIiwiY29uZGl0aW9ucyI6W1siZXEiLCIkYnVja2V0IiwiZ3hibC1zdGFnaW5nIl0sWyJzdGFydHMtd2l0aCIsIiRrZXkiLCJpbWFnZXMvIl1dfQ==",
          "signature": "aLFLRUq8ex4AV0jveeqEvvwjqBE=",
          "expire": "2018-03-16T03:30:35.034Z",
          "dir": "images/"
        }
        ```
      NOTES
      params do
        optional :key, type: String, desc: "文件名"
      end
      get "meta" do
        authenticate!
        present Aliyun::CustomOss.signature
      end
    end
  end
end
