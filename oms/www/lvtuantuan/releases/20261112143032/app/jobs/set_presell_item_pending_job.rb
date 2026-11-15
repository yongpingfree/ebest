# frozen_string_literal: true

class SetPresellItemPendingJob < ApplicationJob
  queue_as :default

  def perform(id)
    item = MagicBean::Item.find(id)
    # 产品如果更新了presell_end_at或者变为非预售商品，则不需要下架
    return if !item.is_presell? || item.presell_end_at > Time.current

    item.pending!

    MagicBean::OperationRecord.create(operatable: item, content: "预售产品: #{item.title} 到期自动下架", store_id: item.store_id, channel: "admin")

    # 产品下架后，需要同步到ES
    # item.reindex(mode: :async)
  end
end
