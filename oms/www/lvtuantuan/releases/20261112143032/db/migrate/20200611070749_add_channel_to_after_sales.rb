# frozen_string_literal: true

class AddChannelToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :channel, :integer
    add_column :after_sales, :payment_type, :string

    say_with_time "update old after_sales' channel" do
      MagicBean::AfterSale.includes(:order).all.each do |as|
        as.update_columns(channel: as.order.channel, payment_type: as.order.payment_type)
      end
    end
  end
end
