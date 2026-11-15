# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuSale < ::CommonEntities::Model
    expose :item_id
    expose :title
    expose :no
    expose :barcode
    expose :human_title
    expose :parent_category_name
    expose :category_name
    expose :category_id
    expose :sum_price_in_yuan
    expose :newest_supplier_name
    expose :newest_supplier_cost_in_yuan
    expose :sum_after_sale_quantity
    expose :sum_after_sale_in_yuan
    expose :shoppingunit

    with_options(format_with: :integer) do
      expose :sales_count
      expose :shopline_sales_count
      expose :shopline_redund_count
    end

    with_options(format_with: :float) do
      expose :sum_price_in_yuan
      expose :sum_original_amount_in_yuan
      expose :shopline_sales_amount
      expose :shopline_redund_amount
    end

    def return_hash
      @return_hash ||= (options[:sku_return_hash] || {})["#{object.id}"]
    end

    def sum_after_sale_quantity
      return_hash.present? ? return_hash[:sum_after_sale_quantity] : 0
    end

    def sum_after_sale_in_yuan
      return_hash.present? ? return_hash[:sum_after_sale_in_yuan] : 0
    end

    def shopline_sale_and_refund_data
      @shopline_sale_and_refund_data ||= (options[:shopline_sale_and_refund_hash] || {})["#{object.no}-#{object.store_id}"]
    end

    def shopline_sales_count
      shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:sales_count] : 0
    end

    def shopline_sales_amount
      shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:sales_amount] : 0
    end

    def shopline_redund_count
      shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:redund_count] : 0
    end

    def shopline_redund_amount
      shopline_sale_and_refund_data.present? ? shopline_sale_and_refund_data[:redund_amount] : 0
    end
  end
end
