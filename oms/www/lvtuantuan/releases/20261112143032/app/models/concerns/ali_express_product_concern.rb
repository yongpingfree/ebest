module AliExpressProductConcern
  extend ActiveSupport::Concern

  DEFAULT_AE_EXCHANGE_RATE = 0.6699
  DEFAULT_AE_FACTOR = 1.3

  def aliexpress_create_item
    return if aliexpress_synced?
    return if on_sale_skus.blank?

    response = Aliexpress::Product.create(self.build_aeop_a_e_product)
    ae_product_id = response.body&.dig("result", "product_id")

    if ae_product_id.present?
      build_ae_item(third_party_id: ae_product_id).save
      build_ae_skus
    end

    response
  end

  def build_ae_skus
    product_resp = Aliexpress::Product.show(ae_item.third_party_id)

    product_result = product_resp&.body.dig("result")
    if product_result.present?
      sku_resp = product_result["aeop_ae_product_s_k_us"].first

      if sku_resp.dig("id").present?
        sku = on_sale_skus.select { |sku| sku.no == sku_resp["sku_code"] }.first
        sku.build_ae_sku(
          third_party_id: sku_resp["id"],
          third_party_inventory_item_id: sku_resp["sku_Id"]
        ).save
      end
    end
  end

  def aliexpress_update_item
    return unless aliexpress_synced?

    aeop_ae_product = self.build_aeop_a_e_product
    aeop_ae_product[:product_id] = ae_item.third_party_id

    # TODO 更改为不获取详情，只用本地数据更新
    detail_response = Aliexpress::Product.show(ae_item.third_party_id)
    detail_result = detail_response.body&.dig("result")

    if ae_category_id.nil?
      aeop_ae_product[:category_id] = detail_result&.dig("category_id")
    end

    if ae_freight_info.nil?
      aeop_ae_product[:package_height] = detail_result&.dig("package_height")
      aeop_ae_product[:package_length] = detail_result&.dig("package_length")
      aeop_ae_product[:package_width] = detail_result&.dig("package_width")
      aeop_ae_product[:gross_weight] = detail_result&.dig("gross_weight")
    end

    if aeop_ae_product[:aeop_ae_product_propertys].blank?
      aeop_ae_product[:aeop_ae_product_propertys] = detail_result&.dig("aeop_ae_product_propertys")
    end

    if detail_result.present?
      # 暂时使用原来的发货时间，因为有些限制 3，有些 7
      delivery_time = detail_result&.dig("delivery_time")
      aeop_ae_product[:delivery_time] = delivery_time if delivery_time.present?
    end

    Aliexpress::Product.update(aeop_ae_product)
  end

  def build_aeop_a_e_product
    detail = {
      "version":"2.0.0",
       "moduleList":[
        {
          "type":"image",
          images: detail_images.map do |image|
            {
              url: image,
            }
          end
        },
       ]
    }

    promise_template_id = Aliexpress::Api.promise_templates.body&.dig('result', 'template_list', 0, 'id')
    freight_template_id = "50116790044"

    skus = self.on_sale_skus.first(1)

    {
      product_price: price_with_fee_in_dollar(skus.first.ae_price_in_yuan_num),
      # currency_code: 'USD',
      # 下单减库存(place_order_withhold)和支付减库存(payment_success_deduct)
      reduce_strategy: 'payment_success_deduct',
      # 服务模板
      promise_template_id: promise_template_id,
      # 运费模版
      freight_template_id: freight_template_id,
      category_id: self.ae_category_id,
      # 备货期
      delivery_time: 7,
      # 毛重
      gross_weight: ae_freight_info&.dig("freight_weight") || [500, [0.001, skus.sum(&:weight_in_gram) / 1000].max].min,
      # http://seller.aliexpress.com/so/tupianguifan.php
      package_height: ae_freight_info&.dig("freight_height") || 1,
      package_length: ae_freight_info&.dig("freight_length") || 1,
      package_width: ae_freight_info&.dig("freight_width") || 1,
      # 打包销售: true 非打包销售:false
      package_type: 'false',
      locale: 'en_US',
      subject_list: [
        {
          locale: 'en_US',
          value:  title_en
        },
      ],
      image_u_r_ls: main_images.first(6).map{ |image| Aliexpress::ImageBank.build(image) }.compact.uniq.join(";"),
      detail_source_list: [
        {
          locale: 'en_US',
          # https://open.aliexpress.com/doc/doc.htm#/?docId=725
          mobile_detail: detail,
          web_detail: detail,
        }
      ],
      aeop_ae_product_propertys: aeop_ae_product_propertys,
      # 至少一个有货状态
      aeop_ae_product_s_k_us: skus.map do |sku|
        {
          sku_price: price_with_fee_in_dollar(sku.ae_price_in_yuan_num),
          sku_code: sku.no,
          currency_code: 'USD',
          ipm_sku_stock: 0, #sku.quantity,
          barcode: sku.barcode,
          aeop_s_k_u_property: [{ property_value_id: 201336099, sku_property_id: 200007763 }],
        }
      end,
    }
  end

  def price_with_fee_in_dollar(price_in_yuan)
    (price_in_yuan * DEFAULT_AE_EXCHANGE_RATE * DEFAULT_AE_FACTOR).round(2)
  end

  def aeop_ae_product_propertys
    ae_product_attributes&.map do |attribute|
      property =  { attr_name_id: attribute["id"].split("--")[-1].strip }

      values = attribute["value"].split("--")
      if values.size == 1
        property[:attr_value] = values[0].strip
      else
        property[:attr_value_id] = values[-1].strip
      end

      property
    end
  end

  def aliexpress_destroy_item
    return unless aliexpress_synced?
    response = Aliexpress::Product.destroy(ae_item.third_party_id)
    if response&.body&.dig("product_id")
      ae_item.destroy
      stock_keeping_units.each do |sku|
        sku.ae_sku&.destroy
      end
    end
  end
end
