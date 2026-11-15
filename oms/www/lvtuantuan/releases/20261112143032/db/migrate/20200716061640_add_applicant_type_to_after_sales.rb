# frozen_string_literal: true

class AddApplicantTypeToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :applicant_type, :integer, default: 1, comment: "申请人类型"
  end
end
