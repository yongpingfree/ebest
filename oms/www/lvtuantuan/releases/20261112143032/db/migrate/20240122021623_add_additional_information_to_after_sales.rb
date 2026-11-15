# frozen_string_literal: true

class AddAdditionalInformationToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :additional_information, :string, comment: "补充说明"
  end
end
