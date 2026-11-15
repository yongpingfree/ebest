# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SkuReturn < ::CommonEntities::Model
    expose :item_id
    expose :title
    expose :no
    expose :barcode
    expose :human_title
    expose :parent_category_name
    expose :category_name
    expose :category_id
    expose :newest_supplier_name

    with_options(format_with: :integer) do
      expose :sum_after_sale_quantity
    end

    with_options(format_with: :float) do
      expose :sum_after_sale_in_yuan
    end
  end
end
