# frozen_string_literal: true

module BeansApp
  class API::V1::Comments < ::API
    namespace :comments, desc: "创建评论" do
      helpers do
        def permitted_params
          [:commentable_type, :commentable_id, :content, :user_id, :stars, images: []]
        end

        def includes
          [:user, :commentable, item: [:translations, :on_sale_skus, :parent_category, :parent_web_category, brand: :translations]]
        end
      end

      desc "创建评论", {
        success: API::Entities::Comment
      }
      params do
        requires :commentable_type, type: String, desc: "可评论资源类型", values: MagicBean::Comment::COMMENTABLE_TYPES
        requires :commentable_id, type: Integer, desc: "可评论资源 ID"
        requires :content, type: String, desc: "内容"
        optional :images, type: Array[String], desc: "图片"
        optional :stars, type: Integer, desc: "星级（兼容旧版设为非必填）"
      end
      post do
        params[:user_id] = current_user&.id
        params[:stars] = 5 if params[:stars].blank?
        authorize_and_create_resource
      end

      desc "用户评价列表", {
        success: API::Entities::Comment,
        is_array: true
      }
      paginate
      get do
        authorize_and_response_collection
      end
    end
  end
end
