# frozen_string_literal: true

class ShoplineController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_signature!

  @@shopline_logger = ::Logger.new("./log/shopline.log")

  def paid_order_notify
    @@shopline_logger.info("Shopline paid order notify params: #{params.to_json}")

    current_store = if peti_store?
      MagicBean::Store.find_by name: "peti"
    else
      MagicBean::Store.find_by name: "Sydney"
    end
    store_site_config = current_store.site_config

    # 判断全站配置中的shopline_order_creation_disabled，如果为true，则不处理订单创建
    if store_site_config&.shopline_order_creation_disabled
      return render plain: "", status: 200
    end

    CreateShoplineOrderJob.perform_later(params["id"], peti_store?, store_site_config.id)

    render plain: "", status: 200
  end

  def refund_notify
    @@shopline_logger.info("Shopline refund notify params: #{params.to_json}")
    order = MagicBean::ThirdPartyOrder.find_by(no: params["order_id"])
    
    if order
      # 退款创建时，状态还是pending，等3分钟再处理退款回调
      refund_line_items = params["refund_line_items"].select { |item| item["restock_type"] == "return" }.map do |item|
        sku = item["line_item"]["sku"]
        next if sku.blank?
        { sku: sku, quantity: item["quantity"] }
      end.compact
      
      ShoplineRefundNotifyJob.set(wait: 3.minutes).perform_later(order.id, refund_line_items)      
    end
  
    render plain: "", status: 200
  end

  private
  def verify_signature!
    app_secret = peti_store? ? Shopline::Api::SHOPLINE_SETTING[:peti_app_secret] : Shopline::Api::SHOPLINE_SETTING[:app_secret]
    return if OpenSSL::HMAC.hexdigest('sha256', app_secret, request.raw_post) == signature
    render json: { error: "Invalid Signature" }, status: :bad_request
  end

  def signature
    request.headers['X-Shopline-Hmac-Sha256']
  end

  def peti_store?
    params["peti_store"] == "true"
  end
end
