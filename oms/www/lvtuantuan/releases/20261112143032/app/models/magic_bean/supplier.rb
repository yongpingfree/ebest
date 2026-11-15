class MagicBean::Supplier < ApplicationRecord
  # concerns
  include PriceConvertConcern

  # scope

  # constants
  IGNORED_SUPPLIER_NAME = "Ebest Adjustment".freeze
  NOTIFICATION_MAX_DELAY_SECONDS = 3600

  # attr related macros
  convert_price_to_yuan :cost_in_cent

  # association macros
  belongs_to :stock_keeping_unit

  # validation macros
  validates :cost_in_cent, :name, presence: true

  # callbacks
  after_commit :send_exception_email_to_admin_when_sku_price_invalid

  # other macros

  # instance methods

  # class methods

  # private methods

  def send_exception_email_to_admin_when_sku_price_invalid
    emails = stock_keeping_unit.store.site_config.sku_price_exception_emails
    return if emails.empty?

    if stock_keeping_unit.price_less_than_supplier_cost_multiple? || stock_keeping_unit.new_user_price_less_than_supplier_cost_multiple?
      # 双11期间会大量更新商品售价，分散 email 发送频率以避免邮件服务商限流
      delay_seconds = rand(NOTIFICATION_MAX_DELAY_SECONDS).seconds
      StockKeepingUnitMailer.notify_price_invalid(emails, stock_keeping_unit).deliver_later(wait: delay_seconds)
    end
  end
end
