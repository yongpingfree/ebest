# frozen_string_literal: true

class AddStatusToInvoices < ActiveRecord::Migration[5.2]
  def change
    add_column :invoices, :status, :integer
    add_column :invoices, :admin_remark, :string
  end
end
