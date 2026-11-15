# frozen_string_literal: true

class AddStatusToIntegralRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :integral_records, :status, :integer, default: 2

    say_with_time "update old integral_records' status" do
      MagicBean::IntegralRecord.reset_column_information

      MagicBean::IntegralRecord.order_paid.find_each do |integral_record|
        status = integral_record.targetable.all_refund_withdraw_integral_records.present? ? "processed" : "pending"
        integral_record.update_columns status: status
      end
    end
  end
end
