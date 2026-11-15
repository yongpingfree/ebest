# frozen_string_literal: true

class AddPaymentCallbackTimeoutEmails < ActiveRecord::Migration[5.2]
  def change
    add_column :site_configs, :payment_callback_timeout_emails, :string, array: true, default: []
  end
end
