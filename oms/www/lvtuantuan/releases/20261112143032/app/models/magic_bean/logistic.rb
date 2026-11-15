# frozen_string_literal: true
module MagicBean
  class Logistic < ApplicationRecord
    # scope
    scope :undelivered, -> { where(is_delivered: false) }

    # constants
    # 澳洲邮局快递状态
    DELIVERED = "Delivered"  # 已收货

    # attr related macros

    # association macros
    belongs_to :order

    # validation macros
    validates :no, uniqueness: true, allow_nil: true, if: -> { ae_order_no.blank? }

    # callbacks
    before_create :format_data
    after_commit :enqueue_tracking_job, on: :create

    # other macros
    delegate :no, :type, to: :order, prefix: true

    def format_data
      self.no = no.to_s.gsub(/\W+/, "") if no.present?
      self.company = company.to_s.strip

      # 跨境购物流不用处理
      if !ae_order_no?
        self.traces = traces&.map do |trace|
          trace["date"] = trace["date"].to_time.strftime("%y-%m-%d %H:%M:%S")
          trace
        end
      end
    end

    def data
      data = if ae_order_no?
        traces&.sort_by { |trace| trace["eta_time_stamps"] }
      else
        traces&.map do |trace|
          trace["date"] = trace["date"].to_time.strftime("%m-%d %H:%M")
          trace
        end
      end
    end

    def generate_fake_no
      loop do
        self.no = SecureRandom.hex(4)
        break unless self.class.exists?(no: no)
      end
    end

    def stock_keeping_units
      MagicBean::StockKeepingUnit.where(id: sku_ids)
    end

    # 测试发货用到
    def order_sku_ids
      order.order_items.map(&:stock_keeping_unit_id).flatten + order.gifts_sku_ids
    end

    private
    def enqueue_tracking_job
      SyncLogisticJob.perform_later(self.id) if ae_order_no.blank?
    end
  end
end
