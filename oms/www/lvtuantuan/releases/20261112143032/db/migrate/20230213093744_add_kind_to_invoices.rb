# frozen_string_literal: true

class AddKindToInvoices < ActiveRecord::Migration[5.2]
  def change
    add_column :invoices, :kind, :integer, default: 1

    say_with_time "update invoices' kind" do
      MagicBean::Invoice.reset_column_information
      MagicBean::Invoice.find_each do |invoice|
        invoice.update_column(:kind, :company) if invoice.alias_name == "公司"
      end
    end
  end
end
