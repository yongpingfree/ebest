# frozen_string_literal: true
module BeansAdmin
  class API::V1::Comments < ::API

    namespace :comments, desc: "Comments API" do
      helpers do
        def comment_ransack_params
          ransack_params.tap { |rp| rp[:item_id_eq] = params[:item_id] }
        end

        def collection_search_sentence
          @collection = end_of_association_chain.top_level.accessible_by(current_ability).includes(includes).ransack(ransack_params)
        end

        def default_order
          ["is_top desc", "id desc"]
        end

        def permitted_params
          [:status, :is_top, :content, :tag_list, :user_nickname, :user_avatar, :item_id, :stock_keeping_unit_id, :parent_id, images: [], tag_list: []]
        end

        # FIXME: 现在commentable只有order_item, 以后如果有别的类型，这里不能直接include
        def includes
          [:taggings, :reply, :user, item: :translations, commentable: :order]
        end
      end

      desc "Comment tags"
      get "tags" do
        MagicBean::Comment.all_tags
      end

      desc "Comments list", {
        success: API::Entities::Comment,
        is_array: true
      }
      params do
        optional :commentable_type, type: String, desc: "可评论资源类型", values: MagicBean::Comment::COMMENTABLE_TYPES
        optional :commentable_id, type: Integer, desc: "可评论资源 ID"
        optional :item_id, type: Integer, desc: "产品 ID"
      end
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新建评论", {
        success: API::Entities::Comment
      }
      params do
        requires :all, using: API::Entities::Comment.documentation.dup.extract!(:status, :is_top, :content, :item_id)
        optional :all, using: API::Entities::Comment.documentation.dup.extract!(:images, :tag_list, :stock_keeping_unit_id, :parent_id, :user_nickname, :user_avatar)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "Comment detail", {
          success: API::Entities::Comment
        }
        get do
          authorize_and_response_resource
        end

        desc "编辑评论", {
          success: API::Entities::Comment
        }
        params do
          optional :all, using: API::Entities::Comment.documentation.dup
        end
        put do
          authorize_and_update_resource
        end

        desc "ban comment", {
          success: API::Entities::SuccessfulResult
        }
        put "ban" do
          authorize! :ban, resource

          if resource.banned!
            response_success
          else
            response_record_error(resource)
          end
        end

        desc "show comment", {
          success: API::Entities::SuccessfulResult
        }
        put "show" do
          authorize! :show, resource

          if resource.show!
            response_success
          else
            response_record_error(resource)
          end
        end

        desc "toggle is top", {
          success: API::Entities::SuccessfulResult
        }
        put "toggle_is_top" do
          authorize! :toggle, resource

          if resource.toggle!(:is_top)
            response_success
          else
            response_record_error(resource)
          end
        end

        desc "Destroy comment", {
          detail: <<-NOTES.strip_heredoc
            ```json
            {
              code: 200,
              message: "ok"
            }
            ```
          NOTES
        }
        delete do
          authorize_and_destroy_resource
        end
      end
    end
  end
end
