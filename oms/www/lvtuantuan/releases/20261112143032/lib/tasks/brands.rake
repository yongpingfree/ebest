# frozen_string_literal: true

namespace :brands do
  desc "Initialize position of all brands by English title"
  task init_position_by_title: :environment do |t, args|
    MagicBean::Brand::Translation.where(locale: "en").order(name: :asc).each.with_index(1) do |cn_translation, idx|
      # 每个品牌排序默认间隔 100，以方便后续插入优先级更高的品牌
      MagicBean::Brand.find(cn_translation.brand_id).update_attribute(:position, idx * 100)
    end
  end
end
