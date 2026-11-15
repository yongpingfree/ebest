# frozen_string_literal: true
module Aliexpress::Sku
  class << self
    @@logger = ::Logger.new("./log/aliexpress.log")

    # aliexpress.postproduct.redefining.editmutilpleskustocks
    # {"sku_id":number1,"sku_id":number2}
    # {\"14:200003699;5:100014064\":240,\"}
    def edit_mutilple_sku_stocks(product_id: nil, sku_stocks: {})
      Aliexpress::Api.request_to_ae("aliexpress.postproduct.redefining.editmutilpleskustocks", "POST", { product_id: product_id, sku_stocks: sku_stocks.to_json }, top_client: true)
    end

    # aliexpress.postproduct.redefining.editsingleskustock
    def edit_single_sku_stock(product_id: nil, sku_id: nil, stock: nil)
      Aliexpress::Api.request_to_ae(
        "aliexpress.postproduct.redefining.editsingleskustock",
        "POST",
        {
          product_id: product_id,
          sku_id: sku_id,
          ipm_sku_stock: stock
        },
        top_client: true
      )
    end

    # aliexpress.offer.product.skuprices.edit
    # sku_id_price_map: "{ \"14:193\": \"0.6\",\"14:175\": \"0.9\"}"
    def edit_sku_prices(product_id: nil, sku_prices: {})
      Aliexpress::Api.request_to_ae("aliexpress.offer.product.skuprices.edit", "POST", { product_id: product_id, sku_id_price_map: sku_prices.to_json }, top_client: true)
    end

    # aliexpress.postproduct.redefining.editsingleskuprice
    def edit_single_sku_price(product_id: nil, sku_id: nil, sku_price: nil)
      Aliexpress::Api.request_to_ae(
        "aliexpress.postproduct.redefining.editsingleskuprice",
        "POST",
        {
          product_id: product_id,
          sku_id: sku_id,
          sku_price: sku_price
        },
        top_client: true
      )
    end
  end
end
