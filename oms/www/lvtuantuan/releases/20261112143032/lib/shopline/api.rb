# frozen_string_literal: true
module Shopline
  class Api
    include HTTParty
  
    SHOPLINE_SETTING = Rails.application.credentials.dig(Rails.env.to_sym, :shopline)
    ADMIN_TOKEN = SHOPLINE_SETTING[:admin_api_token]
    PETI_ADMIN_TOKEN = SHOPLINE_SETTING[:peti_admin_api_token]
    SYDNEY_LOCATION_ID = SHOPLINE_SETTING[:location_id].to_s
    SYDNEY_POST_LOCATION_ID = SHOPLINE_SETTING[:post_location_id].to_s
    SYDNEY_HANDLE = SHOPLINE_SETTING[:handle]
    PETI_LOCATION_ID = SHOPLINE_SETTING[:peti_location_id].to_s
    PETI_POST_LOCATION_ID = SHOPLINE_SETTING[:peti_post_location_id].to_s
    PETI_HANDLE = SHOPLINE_SETTING[:peti_handle]
    VERSION = "v20230901"
    RETRY_TIMES = 3
    INVENTORY_SKU_REDIS_KEY = "shopline_batch_update_inventory_skus"

    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ].freeze

    HTTPARTY_TIMEOUT = 15

    class << self
      @@logger = ::Logger.new("./log/shopline.log")
      def get_customers(page_info: nil, peti_store: false)
        call_httparty("get", "/v2/customers.json?limit=200&page_info=#{page_info}", peti_store: peti_store)
      end

      def customers_count(peti_store = false)
        call_httparty("get", "/customers/v2/count.json", peti_store: peti_store)
      end

      # query例子: "email:xx@xx.com;customer_id:1"
      def search_customers(query, peti_store = false)
        call_httparty("get", "/customers/v2/search.json?query=#{query}", peti_store: peti_store)
      end

      # customer: { "email": email }
      def update_customer_email(customer_id, customer = {}, peti_store = false)
        options = {
          body: {
            "customer": customer
          }
        }

        call_httparty("put", "/customers/#{customer_id}.json", options, peti_store: peti_store)
      end

      # FIXME: 目前分类接口都没用到，先不兼容多门店
      def category_list
        call_httparty("get", "/products/custom_collections.json")
      end

      def create_category(category)
        options = { body: category_body(category) }

        call_httparty("post", "/products/custom_collections.json", options)
      end

      def update_category(category, shopline_category_id)
        options = { body: category_body(category) }

        call_httparty("put", "/products/custom_collections/#{shopline_category_id}.json", options)
      end

      def delete_category(shopline_category_id)
        call_httparty("delete", "/products/custom_collections/#{shopline_category_id}.json")
      end

      def batch_create_category
        # request_body =  MagicBean::WebCategory.show.where.not(parent_id: nil).limit(10).map do |category|
        #   {
        #     "url": "#{Shopline::Api.base_uri}/products/custom_collections.json",
        #     "method": "post",
        #     "payload": {
        #       "custom_collection": {
        #         "image": {
        #           "alt": "",
        #           "src": format_image_url(category.icon)
        #         },
        #         "published_scope": "web",
        #         "sort_order": "updated-asc",
        #         "title": category.name_en,
        #         "handle": "category-#{category.id}",            
        #       }
        #     }
        #   }
        # end

        # file_path = Rails.root.join("public/shopline/category_#{Time.current.to_i}.jsonl")
        # dir = File.dirname(file_path)
        # FileUtils.mkdir_p(dir) unless File.directory?(dir)
        # # 将request_body写入tmp/category.jsonl文件
        # File.open(file_path, "w") do |f|
        #   request_body.each do |line|
        #     f.puts line.to_json
        #   end
        # end

        # options = {}
        # options[:body] = {
        #   "file_url": "https://b37a-120-235-18-130.ngrok-free.app/shopline/category_1714125593.jsonl"
        # }

        # call_httparty("post", "/bulk_operation_run_mutation_general.json", options)
      end

      # 说明文档: https://developer.shopline.com/docsv2/ec20/3cv5d7wpfgr6a8z5/hspjf7d96ykujeya?version=v20250301
      # 接口文档: https://developer.shopline.com/docsv2/ec20/cdb180dc069f7d8d6877c0cdffe96f73/DSAX1G4g?version=v20250301
      def create_bulk_operation(file_path, peti_store = false)
        options = {
          body: { "file_url": file_path }
        }

        call_httparty("post", "/bulk_operation_run_mutation_general.json", options, peti_store: peti_store)
      end

      # 查询批量操作当前状态
      def current_bulk_operation(peti_store = false)
        call_httparty("get", "/current_bulk_operation.json?type=MUTATION_GENERAL", peti_store: peti_store)
      end

      # 取消批量操作
       def cancel_bulk_operation(id, peti_store = false)
        options = {}
        options[:body] = {
          "id": id
        }
        call_httparty("post", "/bulk_operation_run_cancel.json", options, peti_store: peti_store)
      end

      def products_list(peti_store, query = "")
        call_httparty("get", "/products/products.json?#{query}", peti_store: peti_store)
      end

      def get_product(product_id, peti_store)
        call_httparty("get", "/products/#{product_id}.json", peti_store: peti_store)
      end

      def create_product(item)
        options = { body: product_body(item) }

        call_httparty("post", "/products/products.json", options, peti_store: item.peti_store?)
      end

      def update_product(item, shopline_item_id, destroy = false)
        body = if destroy || !item.channel_match?("shopline") || item.on_sale_skus.blank?
          archived_product_body
        else
          product_body(item)
        end
        
        options = { body: body }

        call_httparty("put", "/products/#{shopline_item_id}.json", options, peti_store: item.peti_store?)
      end

      def product_bind_category(product_id, category_id, peti_store = false)
        options = {}

        options[:body] = {
          "collect": {
            "collection_id": category_id,
            "product_id": product_id
          }
        }

        call_httparty("post", "/products/collects.json", options, peti_store: peti_store)
      end

      def set_product_metafields(item, product_id)
        options = {}

        options[:body] = {
          # type列表: https://developer.shopline.com/docsv2/ec20/3cv5d7wpfgr6a8z5/n5rgeucmx1qhhpqw?version=v20241201
          "metafields": [
            {
              "description": "Storage Method",
              "key": "storage_method_key",
              "namespace": "storage_method",
              "owner_id": product_id,
              "owner_resource": "products",
              "type": "single_line_text_field",
              "value": I18n.t("activerecord.attributes.magic_bean/item.storage_methods.#{item.storage_method}", locale: :en)
            },
            {
              "description": "Delivery Method",
              "key": "delivery_method_key",
              "namespace": "delivery_method",
              "owner_id": product_id,
              "owner_resource": "products",
              "type": "multi_line_text_field",
              "value": item.delivery_type.map { |type| I18n.t("activerecord.attributes.magic_bean/order.delivery_types.#{type}", locale: :en) }.join(", ")
            },
            {
              "description": "Is AusPost",
              "key": "is_auspost",
              "namespace": "is_auspost",
              "owner_id": product_id,
              "owner_resource": "products",
              "type": "boolean",
              "value": item.delivery_type.include?("express").to_s # shopline虽然设置boolean, 但传参要求传string
            },
            {
              "description": "Expiration Date",
              "key": "expiration_date",
              "namespace": "expiration_date",
              "owner_id": product_id,
              "owner_resource": "products",
              "type": "single_line_text_field", # date类型无法传空值，所以这里用文本类型
              "value": item.display_expiration_date? ? item.expiration_date&.strftime("%d %B %Y") : nil # 日期格式为 01 January 2022
            },
          ]          
        }

        call_httparty("post", "/metafields_set.json", options, peti_store: item.peti_store?)
      end

      def set_order_metafields(order, order_id)
        options = {}

        options[:body] = {
          # type列表: https://developer.shopline.com/docsv2/ec20/3cv5d7wpfgr6a8z5/n5rgeucmx1qhhpqw?version=v20241201
          "metafields": [
            {
              "description": "Delivery Date",
              "key": "delivery_date",
              "namespace": "delivery_date",
              "owner_id": order_id,
              "owner_resource": "orders",
              "type": "date",
              "value": order.delivery_date
            },
          ]          
        }

        call_httparty("post", "/metafields_set.json", options, peti_store: order.peti_store?)
      end

      def connect_inventory(inventory_item_id, peti_store = false)
        location_ids = peti_store ? [PETI_LOCATION_ID, PETI_POST_LOCATION_ID] : [SYDNEY_LOCATION_ID, SYDNEY_POST_LOCATION_ID]

        errors_count = 0

        location_ids.each do |location_id|
          next if location_id.blank?

          options = {}

          options[:body] = {
            "inventory_item_id": inventory_item_id,
            "location_id": location_id
          }

          res = call_httparty("post", "/inventory_levels/connect.json", options, peti_store: peti_store)
          
          # 如果已经存在则不算错误
          error = res["errors"] || res["error"]
          errors_count += 1 if error.present? && error.exclude?("already exists")
        end

        errors_count
      end

      def update_stock(inventory_item_id, quantity, peti_store = false, item_delivery_type = [])
        # 一个门店要同步多个地点的库存
        location_ids = peti_store ? [PETI_LOCATION_ID, PETI_POST_LOCATION_ID] : [SYDNEY_LOCATION_ID, SYDNEY_POST_LOCATION_ID]

        errors_count = 0

        location_ids.each_with_index do |location_id, index|
          next if location_id.blank?

          tmp_quantity = quantity
          # index: 0为自派/自提，1为邮寄
          # 判断配送方式，来确认同步库存到哪个地点，不可同步则将库存设置为0
          tmp_quantity = 0 if index == 0 && (item_delivery_type & ["merchant_delivery", "self_pick"]).blank?
          tmp_quantity = 0 if index == 1 && item_delivery_type.exclude?("express")

          options = {}

          options[:body] = {
            "available": tmp_quantity,
            "inventory_item_id": inventory_item_id,
            "location_id": location_id
          }

          res = call_httparty("post", "/inventory_levels/set.json", options, peti_store: peti_store)
          errors_count += 1 if res["errors"].present?
        end

        errors_count
      end

      # order_ids: 订单号,多个以逗号分隔，最大支持100个
      def get_orders(order_ids, peti_store = false)
        call_httparty("get", "/orders.json?ids=#{order_ids}", peti_store: peti_store)
      end

      def refund(refund_params, peti_store = false)
        options = { body: refund_params }

        call_httparty("post", "/order/refund.json", options, peti_store: peti_store)
      end

      # 退款试算接口，计算可退金额
      def refund_calculate(order_id, refund_params, peti_store = false)
        options = { body: refund_params }
        call_httparty("post", "/orders/#{order_id}/refunds/calculate.json", options, peti_store: peti_store)
      end

      def deliver(order_id, deliver_params, peti_store = false)
        options = { body: deliver_params }

        call_httparty("post", "/orders/#{order_id}/fulfillments.json", options, peti_store: peti_store)
      end

      def call_httparty(method, path, options = {}, peti_store: false)
        handle = peti_store ? PETI_HANDLE : SYDNEY_HANDLE
        base_uri "https://#{handle}.myshopline.com/admin/openapi/#{VERSION}/".freeze

        tries = RETRY_TIMES
        body = (options[:body] || {})
        headers = (options[:headers] || {}).reverse_merge(
          "Content-Type" => "application/json;charset=UTF-8",
          "Authorization" => "Bearer #{peti_store ? PETI_ADMIN_TOKEN : ADMIN_TOKEN}"
        )

        @@logger.debug("request: method: #{method}, url: #{path}, body: #{body}, headers: #{headers}")
        response = 
          begin
            if method == "get"
              send method, path, headers: headers, timeout: HTTPARTY_TIMEOUT
            else
              send method, path, body: body.to_json, headers: headers, timeout: HTTPARTY_TIMEOUT
            end
          rescue *HTTP_ERRORS => error
            if (tries -= 1) > 0
              retry
            else
              @@logger.debug("response error: #{error}")
              { "msg" => "连接超时" }
            end
          rescue StandardError => error
            # 偶尔出现 undefined method body for nil
            if (tries -= 1) > 0
              retry
            else
              @@logger.debug("response error: #{error}")
              { "msg" => "其他错误" }
            end
          end
        @@logger.debug("response: #{response}, headers: #{response&.headers}")
        response
      end

      # 传给shopline的url不能带参数，需要格式化先
      def format_image_url(url)
        url&.split("?")&.first
      end

      # shopline的电话前面会加上00
      def format_phone(phone)
        "00" + phone if phone
      end

      def category_body(category)
        {
          "custom_collection": {
            "image": {
              "alt": "",
              "src": format_image_url(category.icon)
            },
            "published_scope": "web",
            "sort_order": "updated-asc",
            "title": category.name_en,
            "handle": "category-#{category.id}",            
          }
        }
      end

      def product_body(item)
        images = item.main_images.map do |image|
          {
            "alt": "",
            "src": format_image_url(image)
          }
        end

        # 价格倍率先读取全站配置，如果没有则默认1.2
        shopline_price_rate = item.send(:current_store_site_config).shopline_price_rate.presence || 1.2
        # 如果全站配置设置为0，这里要设置为1.2
        shopline_price_rate = 1.2 if shopline_price_rate.zero?

        variants = item.on_sale_skus.map do |sku|          
          sku_hash = {
            "barcode": sku.barcode,
            "compare_at_price": sku.strikethrough_price_in_cent ? (sku.strikethrough_price_in_yuan_num * shopline_price_rate).round(2).to_s : nil, # 划线价 * 价格倍率
            "image": {
              "alt": "",
              "src": format_image_url(sku.image)
            },
            "inventory_policy": "deny", # 超卖策略：deny - 不允许超卖，continue - 允许超卖
            "inventory_tracker": true,
            "inventory_quantity": sku.quantity,
            "position": sku.position,
            "price": (sku.price_in_yuan_num * shopline_price_rate).round(2).to_s, # 用price_in_yuan * 价格倍率
            "required_shipping": true,
            "sku": sku.no,
            "taxable": sku.gst_percent.positive?, # 是否收税取决于gst_percent的值
            "title": sku.properties_text,
            "weight": sku.weight_in_gram.to_s,
            "weight_unit": "g"
          }

          # 规格值顺序要根据properties的顺序
          sku.properties_array_order_by_vids.each_with_index do |value, index|
            sku_hash["option#{index + 1}"] = value
          end
          sku_hash
        end

        property_hash = {}
        item.on_sale_skus.each do |sku|
          sku.properties_ids_array.each do |property|
            pid, vid = property.split(":")
            property_hash[pid] ||= []
            property_hash[pid] << vid
          end
        end

        item_options = property_hash.map do |pid, vids|
          {
            "name": MagicBean::SkuProperty.find(pid).text_en,
            "values": MagicBean::SkuValue.where(id: vids).map(&:text_en)
          }
        end

        # 如果产品channels移除了shopline, 则将产品归档
        status = item.online? ? "active" : "draft" # 只有on_line状态才传active

        {
          "product": {
            "body_html": item.description_en,
            "handle": item.shopline_handle,
            "images": images,
            "product_category": item.category.name_en,
            "published_scope": "web",
            "spu": item.no,
            "status": status,
            "tags": [item.category.name_en, item.parent_category.name_en], # 不用原来的tags，用一二级分类名
            "title": item.title_en,
            "options": item_options,
            "variants": variants,
            "vendor": item.brand.name_en,
          }
        }
      end

      def archived_product_body
        {
          "product": {            
            "status": "archived",
          }
        }
      end
    end
  end
end
