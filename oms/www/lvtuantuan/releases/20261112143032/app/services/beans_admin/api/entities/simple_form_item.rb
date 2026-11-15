# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleFormItem < MinimalFormItem
    expose :category_name
    expose :category_id, documentation: { type: Integer, desc: "主分类 ID" }
    expose :parent_category_id
    expose :minor_category_name
    expose :minor_category_id, documentation: { type: Integer, desc: "次分类 ID" }
    expose :channels
    expose :listing_type, documentation: { type: String, values: MagicBean::FormItem.listing_types.keys }
    expose :destroyable
    expose :store_name
    expose :cover

    def destroyable
      # 可能传过来是空的数组
      if options[:not_destroyable_item_ids].nil?
        object.destroyable?
      else
        options[:not_destroyable_item_ids].exclude? object.id
      end
    end
  end
end
