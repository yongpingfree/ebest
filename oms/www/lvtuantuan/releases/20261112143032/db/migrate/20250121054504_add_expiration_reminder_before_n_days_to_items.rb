# frozen_string_literal: true

class AddExpirationReminderBeforeNDaysToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :expiration_reminder_before_n_days, :integer, comment: "提前n天提示过期日期弹窗"
  end
end
