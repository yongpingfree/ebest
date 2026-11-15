# frozen_string_literal: true
module Aliexpress
  class Api

    RETRY_TIMES = 3
    ACCESS_TOKEN_KEY = "ae_access_token"
    REFRESH_TOKEN_KEY = "ae_refresh_token"
    OVERSEA_ACCESS_TOKEN_KEY = "ae_oversea_access_token"
    OVERSEA_REFRESH_TOKEN_KEY = "ae_oversea_refresh_token"
    FEED_NAME = "AEB_AU_EbestSelectedItems_20240925"

    HTTP_ERRORS = [
      EOFError,
      Errno::ECONNRESET,
      Errno::EINVAL,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError,
      Timeout::Error
    ].freeze

    class << self
      @@logger = ::Logger.new("./log/aliexpress.log")

      def access_token
        Rails.cache.redis.get(ACCESS_TOKEN_KEY)
      end

      def oversea_access_token
        Rails.cache.redis.get(OVERSEA_ACCESS_TOKEN_KEY)
      end

      def oversea_refresh_token
        Rails.cache.redis.get(OVERSEA_REFRESH_TOKEN_KEY)
      end

      def generate_access_token(code)
        request_to_ae("/auth/token/create", "POST", { code: code }, oversea: false)
      end

      def generate_oversea_access_token(code)
        request_to_ae("/auth/token/create", "POST", { code: code }, oversea: true)
      end

      def refresh_oversea_access_token(refresh_token)
        request_to_ae("/auth/token/refresh", "POST", { refresh_token: refresh_token }, oversea: true) 
      end

      def get_dropshipper_categories(category_id = nil)
        request_to_ae("aliexpress.ds.category.get", "POST", { language: "en", feed_name: FEED_NAME, categoryId: category_id }, top_client: true, oversea: true)
      end

      def get_dropshipper_feednames
        request_to_ae("aliexpress.ds.feedname.get", "POST", top_client: true, oversea: true)
      end

      def get_recommend_products(category_id)
        body = {
          feed_name: FEED_NAME,
          category_id: category_id,
          target_currency: "AUD"
        }
        request_to_ae("aliexpress.ds.recommend.feed.get", "POST", body, top_client: true, oversea: true)
      end

      def get_dropshipper_product_ids(category_id, search_id = "", page_size = "200")
        request_to_ae("aliexpress.ds.feed.itemids.get", "POST", { page_size: page_size, category_id: category_id, feed_name: FEED_NAME, search_id: search_id }, top_client: true, oversea: true)
      end

      # 该接口每天11点-1点会限流，该期间频繁请求失败概率较大
      def get_dropshipper_product_detail(product_id)
        request_to_ae("aliexpress.ds.product.get", "POST", { ship_to_country: "AU", product_id: product_id, target_currency: "AUD", target_language: "EN" }, top_client: true, oversea: true)
      end

      # 返回的delivery_options中code可用于创建订单指定快递
      def freight_query(product_id, sku_id, quantity = 1)
        body = {
          queryDeliveryReq: {
            quantity: quantity,
            shipToCountry: "AU",
            productId: product_id,
            provinceCode: "ACT",
            language: "zh_CN",
            locale: "en_US",
            selectedSkuId: sku_id,
            currency: "AUD"
          }.to_json
        }

        request_to_ae("aliexpress.ds.freight.query", "POST", body, top_client: true, oversea: true)
      end

      def create_ds_order(order)
        mobile_no = order.receiver_tel_number.to_s
        mobile_no = mobile_no.delete_prefix("61") if mobile_no.length > 9

        order_item_list = order.order_items.map do |order_item|
          {
            product_count: order_item.quantity,
            product_id: order_item.item.no,
            sku_attr: order_item.stock_keeping_unit.ae_sku_attr,
            order_memo: order.buyer_message,
            logistics_service_name: MagicBean::Item::AE_CHOICE_DELIVERY_CODE # 用官方配送
          }
        end

        body = {
          ds_extend_request: {
            payment: {
              pay_currency: "AUD",
              try_to_pay: Rails.env.production?.to_s, # 生成环境设置"true", 其他环境"false"
            },
            promotion: {
              promotion_code: "",
              promotion_channel_info: ""
            }            
          }.to_json,
          param_place_order_request4_open_api_d_t_o: {
            logistics_address: {
              country: "AU",
              address: order.full_receiver_address,
              city: order.receiver_city_name,
              zip: order.receiver_postal_code,
              address2: "",
              contact_person: order.ae_drop_shipper_receiver_name,
              mobile_no: mobile_no,
              passport_no: "",
              passport_no_date: "",
              locale: "en_US",
              foreigner_passport_no: "",
              location_tree_address_id: "",
              full_name: order.ae_drop_shipper_receiver_name,
              province: convert_au_province(order.receiver_province_name),
              is_foreigner: "true",
              tax_number: "",
              tax_company: "",
              cpf: "",
              passport_organization: "",
              phone_country: "+61",
              vat_no: ""
            },
            product_items: order_item_list,
            out_order_id: order.no,
          }.to_json
        }

        request_to_ae("aliexpress.ds.order.create", "POST", body, top_client: true, oversea: true)
      end

      def get_merchant_profile
        request_to_ae("aliexpress.merchant.profile.get", "POST", {}, top_client: true)
      end

      def get_category_attributes(category_id)
        request_to_ae("aliexpress.category.redefining.getchildattributesresultbypostcateidandpath", "POST", { param1: category_id.to_i })
      end

      def carmodel_brands
        request_to_ae("aliexpress.carmodel.get.brand", "POST", { param0: { lang: "zh" }.to_json }, top_client: true)
      end

      def merchant_brands
        request_to_ae("aliexpress.merchant.oversea.brand.get", "POST", {}, top_client: true)
      end

      # {"result"=>{"template_list"=>[{"name"=>"Service Template for New Sellers", "id"=>0}]}, "code"=>"0", "request_id"=>"21410fef17158454629484287"}
      def promise_templates(template_id: nil)
        request_to_ae("aliexpress.postproduct.redefining.querypromisetemplatebyid", "POST", { template_id: template_id || -1 }, top_client: true)
      end

      # aliexpress.freight.redefining.listfreighttemplate
      def freight_templates
        request_to_ae("aliexpress.freight.redefining.listfreighttemplate", "POST", {}, top_client: true)
      end

      def get_order_tracking(order_id)
        request_to_ae("aliexpress.ds.order.tracking.get", "POST", { ae_order_id: order_id, language: "en_US" }, top_client: true, oversea: true)
      end

      def order_detail(order_id)
        request_to_ae("aliexpress.trade.ds.order.get", "POST", { single_order_query: { order_id: order_id }.to_json }, top_client: true, oversea: true)
      end

      # api_params = { param1: "123456" }
      def request_to_ae(api_name, method = "POST", api_params = {}, top_client: false, oversea: false)
        request = IopApiClient::Request.new(api_name, method)
        api_params.keys.each do |key|
          if "file_data".eql?(key.to_s)
            request.add_file_parameter(key.to_s, api_params[key])
          else
            request.add_api_parameter(key.to_s, api_params[key])
          end
        end

        request.set_simplify = "true"
        request.set_format("json")

        @@logger.debug("request: api_name: #{api_name}, api_params: #{api_params}")

        response =
          begin
            if oversea
              if top_client
                AEOverseaTopClient.execute(request, oversea_access_token, true)
              else
                AEOverseaClient.execute(request, oversea_access_token)
              end
            else
              if top_client
                AETopClient.execute(request, access_token, true)
              else
                AEClient.execute(request, access_token)
              end
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

          @@logger.debug("response: #{response.body}")
        response
      end

      def convert_au_province(province_abbr)
        province_map = {
          'SA' => 'South Australia',
          'ACT' => 'Australian Capital Territory',
          'QLD' => 'Queensland',
          'TAS' => 'Tasmania',
          'WA' => 'Western Australia',
          'NSW' => 'New South Wales',
          'NT' => 'Northern Territory',
          'VIC' => 'Victoria'
        }
        province_map[province_abbr.to_s.upcase] || province_abbr
      end
    end
  end
end
