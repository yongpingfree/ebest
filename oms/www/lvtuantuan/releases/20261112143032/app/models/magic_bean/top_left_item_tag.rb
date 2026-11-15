# frozen_string_literal: true

module MagicBean
  class TopLeftItemTag < ApplicationRecord
    # scope
    scope :active, -> { where("end_at >= :time AND start_at <= :time", { time: Time.current }) }

    # constants

    # attr related macros

    # association macros
    belongs_to :store

    # validation macros
    validates :name, presence: true
    validates :icon, presence: true
    validates :start_at, presence: true, timeliness: { before: :end_at }
    validates :end_at, presence: true, timeliness: { after: lambda { Time.current }, message: "需大于当前时间" }
    validate :check_item_used?

    # callback

    # other macros
    delegate :name, to: :store, prefix: true

    def items
      MagicBean::Item.includes(:translations).where(id: item_ids)
    end

    private

    def check_item_used?
      return if item_ids.blank?
      
      # 判断在有效期内，是否有其他记录也有相同item
      enabled_item_ids = MagicBean::TopLeftItemTag.where.not(id: self.id).where(":start_at < end_at AND :end_at > start_at", start_at: start_at, end_at: end_at).pluck(:item_ids).flatten.uniq
      return if enabled_item_ids.blank?

      used_item_titles = []

      MagicBean::Item.includes(:translations).where(id: (item_ids & enabled_item_ids)).each do |item|
        used_item_titles << "#{item.title}(#{item.no})"
      end

      errors.add(:base, "同个产品在同个时间段只能设置一个左上角标签，#{used_item_titles.join(", ")} 所属产品已设置左上角标签") if used_item_titles.present?
    end
  end
end
