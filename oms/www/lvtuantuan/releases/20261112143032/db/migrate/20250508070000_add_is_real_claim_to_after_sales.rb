# frozen_string_literal: true

class AddIsRealClaimToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :is_real_claim, :boolean, default: false, comment: '是否真实理赔'
  end
end
