# frozen_string_literal: true

module BeansApp::API::Entities
  class SimpleItem < MinimalItem
    expose :description
    expose :ae_h5_description, documentation: { type: String, desc: "跨境购商品描述" }
    expose :monthly_sales_count
    expose :display_sales_count
    expose :sales_count
    expose :listing_type, documentation: { type: String, desc: "上架类型", values: MagicBean::Item.listing_types.keys }
    expose :production_place
    expose :allergen
    expose :serving_per_package
    expose :serving_size
    expose :parent_category_need_age_verification, documentation: { desc: "一级分类是否需要年龄校验" }
    expose :parent_web_category_need_age_verification, documentation: { desc: "网站一级分类是否需要年龄校验" }
    expose :parent_category_id, documentation: { desc: "一级分类 ID" }
    expose :parent_web_category_id, documentation: { desc: "一级分类 ID" }
    expose :brand_name
    expose :brand_cover
    expose :ingredient
    expose :tmp_nutrition, as: :nutritionValues

    # TODO APP 分类改版发布后 移除
    def monthly_sales_count
      object.display_sales_count
    end

    # app详情页加载成分表数据会报错，这里做兼容，后续修复再删掉
    def tmp_nutrition
      []
    end
  end
end
