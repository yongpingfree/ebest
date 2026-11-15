# frozen_string_literal: true

class SendSkuSalesMailerJob < ApplicationJob
  queue_as :default

  def perform(id)
    sku_sales_mailer_setting = MagicBean::SkuSalesMailerSetting.find_by(id: id)
    return if sku_sales_mailer_setting.blank? || !sku_sales_mailer_setting.enabled

    tomorrow_send_at = sku_sales_mailer_setting.send_at.in_time_zone + 1.day

    # 每周任务需要判断当前时间是否在weekdays中, 若不在，则触发下一次任务
    if sku_sales_mailer_setting.weekly? && !Time.current.wday.to_s.in?(sku_sales_mailer_setting.weekdays)
      SendSkuSalesMailerJob.set(wait_until: tomorrow_send_at).perform_later(id)
      return
    end

    # 执行发邮件任务
    StockKeepingUnitMailer.sku_sales_by_setting(id).deliver_later
    
    if sku_sales_mailer_setting.single?
      # 单次发完后将设置为不启用，用update_columns是为了不触发after_commit回调
      sku_sales_mailer_setting.update_columns(enabled: false)
    else
      # 每日/每周发完后, 触发第二天定时任务
      SendSkuSalesMailerJob.set(wait_until: tomorrow_send_at).perform_later(id)
    end
  end
end

