# frozen_string_literal: true

module ApiHelpers
  module BaseHelper
    def respond_token(user)
      encoded_token = JsonWebToken.encode({
        user_id: user.id
      })

      { token: encoded_token }
    end

    def response_success(message = "OK", options = {})
      { code: 200, message: message }.merge(options)
    end

    def response_error(message = "error", status_code = 400)
      error!({ error_message: message }, status_code)
    end

    def response_record_error(object)
      response_error(object.errors.full_messages.join("，"))
    end

    # shopline的status_code要求返回200
    def response_shopline_error(message = "error", status_code = 200)
      error!({ rescode: "400", resmsg: message, message: message }, status_code)
    end

    def response_shopline_success(options = {})
      { rescode: "0", resmsg: "succ" }.merge(options)
    end

    def ip_address
      (request.env["action_dispatch.remote_ip"] || request.ip).to_s
    end

    def standard_update(object, params, entities)
      if object.update(params)
        present object, with: entities
      else
        response_record_error(object)
      end
    end

    def standard_save(object, entities)
      if object.save
        yield object if block_given?

        present object, with: entities
      else
        response_record_error(object)
      end
    end

    def standard_destroy(object)
      if object.destroy
        response_success
      else
        response_record_error(object)
      end
    end

    def ebest_channel
      case request.headers["Ebest-Channel"]
      when "app", "mini_program", "web"
        request.headers["Ebest-Channel"]
      else
        "mini_program"
      end
    end

    # 未登录认为是新用户
    def is_new_user
      current_user ? current_user.new_user : true
    end

    def like_item_ids
      current_user ? current_user.like_items.ids : []
    end

    def active_top_left_item_hash
      return @active_top_left_item_hash if @active_top_left_item_hash.present?
      @active_top_left_item_hash = {}
      MagicBean::TopLeftItemTag.ransack(store_id_eq: current_store_id).result.active.each do |tag|
        # 避免有的icon重复，导致item_ids被覆盖
        @active_top_left_item_hash[tag.icon] ||= []
        @active_top_left_item_hash[tag.icon] += tag.item_ids
      end
      @active_top_left_item_hash
    end

    # 有专属优惠券的产品信息
    def exclusive_coupon_item_info
      return @exclusive_coupon_item_info if @exclusive_coupon_item_info.present?
      @exclusive_coupon_item_info = { item_ids: [], category_ids: [], sub_category_ids: [], brand_ids: [], custom_list_ids: [] }
      MagicBean::CouponTemplate.active.item_display.where(store_id: current_store_id).where("item_ids != '{}' or category_ids != '{}' or sub_category_ids != '{}' or brand_ids != '{}' or custom_list_ids != '{}'").each do |template|
        [:item_ids, :category_ids, :sub_category_ids, :brand_ids, :custom_list_ids].each do |key|
          @exclusive_coupon_item_info[key] += template.send(key)
        end
      end

      # 产品判断自定义列表id会有性能问题，这里先把item_ids取出来
      if @exclusive_coupon_item_info[:custom_list_ids].present?
        @exclusive_coupon_item_info[:item_ids] += MagicBean::CustomListItem.where(custom_list_id: @exclusive_coupon_item_info[:custom_list_ids].uniq).pluck(:item_id)
        @exclusive_coupon_item_info.delete(:custom_list_ids)
      end

      # 数组去重
      @exclusive_coupon_item_info.keys.each do |key|
        @exclusive_coupon_item_info[key].uniq!
      end

      @exclusive_coupon_item_info
    end

    # 买N折扣的产品信息，如果产品有多个买N折扣的SKU，则取最小的N值
    def buy_n_discount_item_info
      return @buy_n_discount_item_info if @buy_n_discount_item_info.present?
      @buy_n_discount_item_info = {}

      MagicBean::StockKeepingUnit.where(store_id: current_store_id).where.not(discount_quantity: nil, discount_price_in_cent: nil).each do |sku|
        @buy_n_discount_item_info[sku.item_id] = sku.discount_quantity if sku.discount_quantity < (@buy_n_discount_item_info[sku.item_id] || Float::INFINITY)
      end

      @buy_n_discount_item_info
    end

    # 优惠池产品信息
    def preferential_pool_item_infos
      return @preferential_pool_item_infos if @preferential_pool_item_infos.present?

      @preferential_pool_item_infos = MagicBean::PreferentialPool.active.where(store_id: [nil, current_store_id]).map do |pool|
        {
          kind: pool.kind,
          item_ids: MagicBean::StockKeepingUnit.where(id: pool.sku_ids).pluck(:item_id).uniq,
          title: pool.title
        }
      end

      @preferential_pool_item_infos
    end

    # 允许搜索同标签商品的信息
    def allow_view_same_tag_items_info
      return @allow_view_same_tag_items_info if @allow_view_same_tag_items_info.present?
      @allow_view_same_tag_items_info = {}
      MagicBean::ItemTagRelation.includes(item_tag: :translations).where(allow_view_same_tag_items: true).each do |relation|
        @allow_view_same_tag_items_info[relation.item_tag_id] ||= { item_ids: [], item_tag_name: relation.item_tag_name }
        @allow_view_same_tag_items_info[relation.item_tag_id][:item_ids] << relation.item_id
      end

      @allow_view_same_tag_items_info
    end
  end
end
