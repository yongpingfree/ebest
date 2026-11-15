# frozen_string_literal: true

class AddSkipZeroSalesSkusToSkuSalesMailerSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :sku_sales_mailer_settings, :skip_zero_sales_skus, :boolean, default: true, comment: "是否过滤掉销量为0的sku"
  end
end
