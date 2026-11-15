# frozen_string_literal: true

module BeansApp
  class API::V1::Auction::Activities < ::API
    namespace :auction_activities, desc: "拍卖活动 API" do
      helpers do
        def end_of_association_chain
          resource_class.where(store_id: current_store_id).show_on_app
        end

        def includes
          [:translations]
        end

        def resource_class
          MagicBean::Auction::Activity
        end

        def collection_entity
          BeansApp::API::Entities::Auction::SimpleActivity
        end

        def entity_namespace_name
          "BeansApp::API::Entities::Auction".freeze
        end
      end

      desc "拍卖列表", {
        success: API::Entities::Auction::SimpleActivity,
        is_array: true,
        skip_authentication: true
      }
      paginate
      params do
        optional :order_by, type: String, desc: "排序：final_end_at desc/asc | bids_count desc/asc | best_bid_amount_in_cent desc/asc`"
        optional :keyword_cont_any, types: [String, Array], desc: "搜索拍卖标题、描述，多个关键字用空格分割", coerce_with: ->(val) { val.to_s.split(" ") }
        optional :category_id_eq, type: Integer, desc: "产品分类ID", as: :minor_category_id_or_category_id_eq
        optional :best_bid_amount_in_cent_gteq, type: Integer, coerce_with: ->(val) { val.blank? ? nil : (val.to_f * 100).to_i }, desc: "价格区间最低价（传入值货币为元，例如：1.60）"
        optional :best_bid_amount_in_cent_lteq, type: Integer, coerce_with: ->(val) { val.blank? ? nil : (val.to_f * 100).to_i }, desc: "价格区间最高价（传入值货币为元，例如：10.60）"
        optional :reserve_price_in_cent_not_null, type: Grape::API::Boolean, desc: "true: 商品有拍卖底价，false：商品无拍卖底价"
        optional :directly_purchase_price_in_cent_not_null, type: Grape::API::Boolean, desc: "true: 商品可直接购买，默认不传值"
        optional :auto_renewal_end_at_eq, type: Grape::API::Boolean, desc: "true: 拍卖时间自动延长，false: 拍卖时间不会自动延长"
      end
      get do
        params[:store_id_eq] = current_store_id

        authorize_and_response_collection
      end

      route_param :id do
        helpers do
          def current_auction_activity
            @current_auction_activity ||= MagicBean::Auction::Activity.find(params[:id])
          end

          def authorize_member!
            response_error I18n.t("grape.users.become_member_first") unless current_user.member
          end

          def resource
            @resource ||= resource_class.find(params[:id])
          end
        end

        desc "拍卖活动详情", {
          success: API::Entities::Auction::Activity,
          skip_authentication: true
        }
        get do
          authorize_and_response_resource
        end

        namespace :bids, desc: "出价记录" do
          desc "出价记录列表", {
            success: API::Entities::Auction::Bid,
            is_array: true,
            skip_authentication: true
          }
          paginate
          get do
            present paginate(current_auction_activity.bids.includes(:user)), with: API::Entities::Auction::Bid
          end
        end

        namespace :direct_bids, desc: "直接出价" do
          desc "新增直接出价", {
            success: API::Entities::Auction::Bid
          }
          params do
            requires :amount_in_yuan, type: Float, desc: "出价，最多两位小数"
          end
          post do
            authorize_member!
            response_error I18n.t("grape.auction_activities.can_not_create_bid") unless current_auction_activity.bidding?

            bid = current_auction_activity.add_new_direct_bid(user: current_user, member_id: current_user.member_id, amount_in_yuan: params[:amount_in_yuan])

            if bid.present?
              if bid.persisted?
                present bid, with: API::Entities::Auction::Bid
              else
                response_record_error bid
              end
            else
              response_error I18n.t("grape.auction_activities.can_not_create_bid")
            end
          end
        end

        namespace :automatic_bids, desc: "自动出价" do
          desc "新增自动出价，若已出价，则更新最新的自动出价", {
            success: API::Entities::SuccessfulResult
          }
          params do
            requires :amount_limit_in_yuan, type: Float, desc: "最高出价，最多两位小数"
          end
          post do
            authorize_member!
            response_error I18n.t("grape.auction_activities.can_not_create_bid") unless current_auction_activity.bidding?

            existing_automatic_bids = current_auction_activity.automatic_bids.ransack(user_id_eq: current_user.id, amount_limit_in_cent_gteq: current_auction_activity.best_bid_amount_in_cent).result
            if existing_automatic_bids.size > 0
              auto_bid = existing_automatic_bids.first
              if auto_bid.update(amount_limit_in_yuan: params[:amount_limit_in_yuan])
                response_success
              else
                response_record_error auto_bid
              end
            else
              begin
                auto_bid = current_auction_activity.add_new_automatic_bid!(user_id: current_user.id, amount_limit_in_yuan: params[:amount_limit_in_yuan])

                response_error I18n.t("grape.auction_activities.can_not_create_bid") if auto_bid.blank?

                if auto_bid.persisted?
                  response_success
                else
                  response_record_error auto_bid
                end
              rescue ActiveRecord::RecordInvalid => err
                response_error err.message
              end
            end
          end

          desc "当前用户最高自动出价", {
            success: API::Entities::Auction::AutomaticBid
          }
          get :highest do
            highest_auto_bid = current_auction_activity.automatic_bids.find_by(user_id: current_user.id)

            if highest_auto_bid
              present highest_auto_bid, with: API::Entities::Auction::AutomaticBid
            else
              present nil
            end
          end
        end
      end
    end
  end
end
