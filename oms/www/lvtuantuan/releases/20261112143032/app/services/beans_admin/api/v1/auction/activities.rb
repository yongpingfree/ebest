# frozen_string_literal: true

module BeansAdmin
  class API::V1::Auction::Activities < ::API
    namespace :auction_activities, desc: "拍卖活动 API" do
      helpers do
        def includes
          [:translations, :category, :minor_category, :brand, :qa_and_guarantee]
        end

        def resource_class
          ::MagicBean::Auction::Activity
        end

        def collection_entity
          ::BeansAdmin::API::Entities::Auction::SimpleActivity
        end

        def entity_namespace_name
          "BeansAdmin::API::Entities::Auction".freeze
        end

        def permitted_params
          resource_class.globalize_attribute_names + [
            :cover, :start_at, :default_end_at, :auto_renewal_end_at,
            :starting_price_in_yuan, :bidding_increments_in_yuan,
            :reserve_price_in_yuan, :directly_purchase_price_in_yuan,
            :category_id, :minor_category_id, :store_id,
            :brand_id, :qa_and_guarantee_id,
            main_images: [], detail_images: []
          ]
        end
      end

      desc "拍卖列表", {
        success: API::Entities::Auction::SimpleActivity,
        is_array: true,
      }
      paginate
      get do
        authorize_and_response_collection
      end

      desc "新增拍卖", {
        success: API::Entities::Auction::Activity
      }
      params do
        requires :all, using: API::Entities::Auction::Activity.documentation.dup.extract!(:title_zh_cn, :description_zh_cn, :cover, :category_id, :detail_images, :main_images, :start_at, :default_end_at, :starting_price_in_yuan, :bidding_increments_in_yuan)
      end
      post do
        authorize_and_create_resource
      end

      route_param :id do
        desc "拍卖活动详情", {
          success: API::Entities::Auction::Activity
        }
        get do
          authorize_and_response_resource
        end

        desc "更新", {
          success: API::Entities::Auction::Activity,
          skip_store_id: true
        }
        put do
          response_error "不能更新已发布拍卖" unless resource.can_edit?

          authorize_and_update_resource
        end

        desc "发布拍卖", {
          success: API::Entities::Auction::Activity
        }
        put :publish do
          authorize_and_run_member_action(:publish!)
        end


        desc "删除直播间", {
          success: API::Entities::SuccessfulResult
        }
        delete do
          if resource.destroyable?
            authorize_and_destroy_resource
          else
            response_error "不能删除已经开始的拍卖"
          end
        end
      end
    end
  end
end
