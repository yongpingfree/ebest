# frozen_string_literal: true

module BeansAdmin
  class API::V1::AwsOss < ::API
    namespace :aws_oss, desc: "亚马逊云" do
      desc "获取AWS预签名", detail: <<-NOTES.strip_heredoc
        返回预签名

        ```json
        {
          "presigned_url": "https://lvtuantuan-staging.s3.ap-southeast-2.amazonaws.com/images/7f34fe65-ed7d-4c52-9b37-a7c3ef19a446-alex_test.jpg?x-amz-acl=public-read&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIA2UC27W5SFDCSIQQD%2F20240702%2Fap-southeast-2%2Fs3%2Faws4_request&X-Amz-Date=20240702T064624Z&X-Amz-Expires=600&X-Amz-SignedHeaders=host&X-Amz-Signature=02de2974bf9f45f18096c9adad280c900b224d7c5b1b1a7e80cefa7537816413",
          "public_url": "https://lvtuantuan-staging.s3.ap-southeast-2.amazonaws.com/images/7f34fe65-ed7d-4c52-9b37-a7c3ef19a446-alex_test.jpg"
        }
        ```
      NOTES
      params do
        requires :key, type: String, desc: "文件名"
        requires :content_type, type: String
      end
      get "meta" do
        authenticate!
        
        s3 = Aws::S3::Resource.new
        bucket = s3.bucket(AWS_SETTING[:bucket])
        file_name = params[:key].split("/").last
        key = "images/#{SecureRandom.uuid}-#{file_name}"

        object = bucket.object(key)
        if object.exists?
          response_error("文件已存在")
        else
          # 为防止链接泄露，设置过期时间为10分钟
          presigned_url = object.presigned_url(
            :put,
            expires_in: 600,
            content_type: params[:content_type],
            acl: "public-read"
          )

          public_url = object.public_url

          if Rails.env.production?
            # 生产环境需要把aws的host替换成加速cdn的host
            public_url.gsub!(AWS_SETTING[:host], AWS_SETTING[:cdn_host])
          end          
          # # 图片需要把aws的host替换成缩略图地址
          # if params[:content_type].include?("image")
          #   public_url.gsub!(AWS_SETTING[:host], AWS_SETTING[:thumbnail_prefix_path])
          #   # staging没使用cloudfront, 静态访问页面只支持http，需要把https替换成http
          #   public_url.gsub!("https://", "http://") unless Rails.env.production?
          # end

          { presigned_url: presigned_url, public_url: public_url }
        end
      end
    end
  end
end
