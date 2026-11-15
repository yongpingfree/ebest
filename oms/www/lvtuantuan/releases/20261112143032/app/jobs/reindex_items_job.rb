# frozen_string_literal: true

class ReindexItemsJob < ApplicationJob
  queue_as :searchkick

  # 为了避免个别情况没更新ES的产品数据，每天凌晨再定时同步一次
  def perform(*)
    # 全部导入会报错，这里分批次导入
    # 数据结构有变化时还是需要使用MagicBean::Item.reindex，目前数据结构没变化，可以分批导入
    # 只同步今天还没同步的数据
    MagicBean::Item.where(batch_reindex_date: nil).or(MagicBean::Item.where.not(batch_reindex_date: Date.current)).on_sale.each_slice(100) do |items|
      # slice后的items无法直接调用reindex，需要重新查询一遍再reindex
      items = MagicBean::Item.where(id: items.map(&:id))
      items.reindex(mode: :inline)
      items.update_all(batch_reindex_date: Date.current)
    end
  end
end
