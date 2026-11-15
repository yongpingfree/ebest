# frozen_string_literal: true

module BeansAdmin::API::Entities
  class Logistic < ::CommonEntities::Model
    expose :no
    expose :company
    expose :data, as: :traces
    expose :remark
    expose :order_id
    expose :order_no
    expose :order_type
    expose :ae_order_no
    expose :latest_trace_info do |instance, _|
      if instance.ae_order_no?
        instance.traces&.first&.dig("detail_node_list")&.first&.dig("tracking_detail_desc")
      else
        instance.traces&.first&.dig("description").to_s
      end
    end
    expose :stock_keeping_units, using: ::BeansAdmin::API::Entities::StockKeepingUnit
  end
end
