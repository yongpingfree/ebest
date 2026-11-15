# frozen_string_literal: true
module Aliexpress::Product
  class << self
    @@logger = ::Logger.new("./log/aliexpress.log")

    # {"result"=>{"product_id"=>1005007017912340}, "request_id"=>"2101042b17159417931665363"}
    def create(aeop_a_e_product)
      Aliexpress::Api.request_to_ae("aliexpress.offer.product.post", "POST", { aeop_a_e_product: aeop_a_e_product.to_json }, top_client: true)
    end

    # product_status_type: 上架:onSelling ；下架:offline ；审核中:auditing ；审核不通过:editingRequired；客服删除:service_delete ; 所有删除商品：deleted
    def list(product_status_type, current_page: 1, page_size: 20)
      Aliexpress::Api.request_to_ae(
        "aliexpress.postproduct.redefining.findproductinfolistquery",
        "POST",
        {
          aeop_a_e_product_list_query: { product_status_type: product_status_type, current_page: current_page, page_size: page_size }.to_json
        },
        top_client: true
      )
    end

    def show(product_id)
      Aliexpress::Api.request_to_ae("aliexpress.offer.product.query", "POST", { product_id: product_id }, top_client: true)
    end

    def update(aeop_a_e_product)
      # aliexpress.offer.product.edit
      Aliexpress::Api.request_to_ae("aliexpress.offer.product.edit", "POST", { aeop_a_e_product: aeop_a_e_product.to_json }, top_client: true)
    end

    def destroy(product_id)
      Aliexpress::Api.request_to_ae("aliexpress.offer.product.delete", "POST", { product_id: product_id }, top_client: true)
    end

    def draft(current_page: 1, page_size: 20)
      Aliexpress::Api.request_to_ae(
        "aliexpress.offer.draftproducts.get",
        "POST",
        { aeop_a_e_product_list_query: { current_page: 1, page_size: 20 } },
        top_client: true
      )
    end
  end
end


