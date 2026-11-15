# frozen_string_literal: true

class SyncAeOrderTrackingsEveryDayJob < ApplicationJob
  queue_as :aliexpress

  def perform
    return unless Rails.env.production?

    MagicBean::Order.where(ae_drop_shipper: true).where(status: ["wait_seller_send_goods", "wait_buyer_confirm_goods"]).find_each do |order|
      order.sync_ae_order_trackings
    end
  end
end
