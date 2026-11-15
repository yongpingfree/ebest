# frozen_string_literal: true

module BeansAdmin::API::Entities
  class SimpleSkuSalesMailerSetting < ::CommonEntities::Model
    expose :id, :title, :receiver_emails, :cc_emails, :deliver_after_n_days, :contains_order_gift, :contains_order_pool_gift, :send_at, :send_frequency, :weekdays, :sku_search_type, :sku_search_conditions, :sku_ids, :enabled, :store_id, :skip_zero_sales_skus
    expose :store_name
  end
end
