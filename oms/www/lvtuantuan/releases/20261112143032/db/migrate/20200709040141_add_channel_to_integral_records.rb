# frozen_string_literal: true

class AddChannelToIntegralRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :integral_records, :channel, :integer, default: 1

    say_with_time "update old after_sales' channel" do
      MagicBean::IntegralRecord.find_each do |ir|
        targetable = ir.targetable
        channel =
          if ir.targetable_type.eql?(MagicBean::Order) && targetable.paid_at.present?
            targetable.completed_charge_payment.channel
          elsif ir.targetable_type.eql?(MagicBean::AfterSale)
            targetable.order.completed_charge_payment.channel
          elsif targetable.respond_to? :channel
            targetable.channel
          else
            "mini_program"
          end
        ir.update_columns(channel: channel)
      end
    end
  end
end
