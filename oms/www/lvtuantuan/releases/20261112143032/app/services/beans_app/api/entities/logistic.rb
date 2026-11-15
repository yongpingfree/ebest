# frozen_string_literal: true

module BeansApp::API::Entities
  class Logistic < ::CommonEntities::Model
    expose :company, documentation: { desc: "物流公司" }
    expose :no, documentation: { desc: "物流单号" }
    expose :data, documentation: { type: Hash, is_array: true, desc: "物流详情" }
    expose :remark, documentation: { desc: "备注" }
    expose :sku_ids, documentation: { desc: "商品 IDs" }
    expose :ae_order_no, documentation: { desc: "AE订单号" }
  end
end
