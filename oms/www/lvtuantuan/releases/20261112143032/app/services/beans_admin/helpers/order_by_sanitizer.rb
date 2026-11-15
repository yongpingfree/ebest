# frozen_string_literal: true

module BeansAdmin::Helpers
  # order_by 参数最终会进入 reorder/order 拼接 SQL，属注入面。
  # 策略是「清洗不拒绝」：仅保留 "列[.关联列] asc|desc" 片段，其余静默丢弃，
  # 合法前端值（表格组件拼出 `${prop} ${asc|desc}`）不受影响。
  module OrderBySanitizer
    FRAGMENT_PATTERN = /\A[a-z_][a-z_0-9]*(\.[a-z_][a-z_0-9]*)?\s+(asc|desc)\z/i.freeze

    module_function

    def sanitize_fragments(order_by)
      order_by.to_s.split(",").map(&:strip).compact.select { |fragment| fragment.match?(FRAGMENT_PATTERN) }
    end

    def sanitize(order_by)
      sanitize_fragments(order_by).join(", ")
    end
  end
end
