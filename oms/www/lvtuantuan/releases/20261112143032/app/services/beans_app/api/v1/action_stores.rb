# frozen_string_literal: true

module BeansApp
  class API::V1::ActionStores < ::API

    TARGET_TYPE_ARRAY = ["MagicBean::Item", "MagicBean::Comment"]

    namespace :action_stores, desc: "用户行为" do
      helpers do
        def check_action_type!
          unless MagicBean::User.defined_actions.any? { |action| action[:target_type] == params[:target_type] && action[:action_type] == params[:action_type] }
            error!("action_type does not have a valid value")
          end
        end

        def collection
          @collection ||= params[:target_type].classify.constantize
        end

        def resource
          @resource ||= collection.find(params[:target_id])
        end
      end

      desc "获取用户行为列表，如收藏商品列表", {
        detail: <<-NOTES.strip_heredoc
        不同的target_type返回不同的格式
        NOTES
      }
      paginate
      params do
        requires :action_type, type: String, values: ["like"], desc: "行为"
        requires :target_type, type: String, desc: "对象类型", values: TARGET_TYPE_ARRAY
        optional :order_by, type: String, allow_blank: true, values: ["price_in_cent asc", "price_in_cent desc", "actions.created_at asc", "actions.created_at desc"], desc: "排序，只针对商品的情况"
      end
      get do
        check_action_type!

        entity =
          begin
            "BeansApp::API::Entities::Simple#{params[:target_type].demodulize}".constantize
          rescue NameError => _
            "BeansApp::API::Entities::#{params[:target_type].demodulize}".constantize
          end
        
        collection = current_user.send("#{params[:action_type]}_#{params[:target_type].demodulize.underscore.pluralize}")
        
        groupon_activities = []

        if params[:target_type] == "MagicBean::Item"
          like_item_ids = current_user.like_items.ids
          collection = collection.includes([:on_sale_skus, :parent_category, :parent_web_category, :translations, brand: :translations, category: :translations])
          collection = collection.reorder(params[:order_by]) if params[:order_by].present?
          groupon_activities = MagicBean::GrouponActivity.published.going.where(item_id: collection.page(params[:page].to_i).per(params[:per_page].to_i).padding(params[:offset].to_i).map(&:id))
        else
          like_item_ids = []
        end
        
        present paginate(collection), with: entity, like_item_ids: like_item_ids, groupon_activities: groupon_activities, is_new_user: is_new_user, active_top_left_item_hash: active_top_left_item_hash, exclusive_coupon_item_info: exclusive_coupon_item_info,
          buy_n_discount_item_info: buy_n_discount_item_info, preferential_pool_item_infos: preferential_pool_item_infos, allow_view_same_tag_items_info: allow_view_same_tag_items_info
      end

      desc "创建用户行为，如收藏商品", {
        detail: <<-NOTES.strip_heredoc
        ```json
        {
          code: 200,
          message: "ok"
        }
        ```
        NOTES
      }
      params do
        requires :action_type, type: String, values: ["like"], desc: "行为"
        requires :target_type, type: String, desc: "对象类型", values: TARGET_TYPE_ARRAY
        requires :target_id, type: String, desc: "对象id"
      end
      post do
        check_action_type!

        resource = collection.find(params[:target_id])

        if current_user.send "#{params[:action_type]}_#{params[:target_type].demodulize.underscore}?", resource
          response_error I18n.t("grape.action_stores.already_done")
        end

        if current_user.create_action(params[:action_type], target: resource)
          response_success
        else
          response_error I18n.t("grape.action_stores.action_failed")
        end
      end

      desc "销毁用户行为，如取消收藏商品", {
        detail: <<-NOTES.strip_heredoc
        ```json
        {
          code: 200,
          message: "ok"
        }
        ```
        NOTES
      }
      params do
        requires :action_type, type: String, values: ["like"], desc: "行为"
        requires :target_type, type: String, desc: "对象类型", values: TARGET_TYPE_ARRAY
        requires :target_id, type: String, desc: "对象id"
      end
      delete do
        check_action_type!

        if current_user.destroy_action(params[:action_type], target: resource)
          response_success
        else
          response_error I18n.t("grape.action_stores.action_failed")
        end
      end
    end
  end
end
