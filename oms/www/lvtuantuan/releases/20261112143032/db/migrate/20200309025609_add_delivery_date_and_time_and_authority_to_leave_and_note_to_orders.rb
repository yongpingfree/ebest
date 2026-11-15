# frozen_string_literal: true

class AddDeliveryDateAndTimeAndAuthorityToLeaveAndNoteToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :delivery_date, :string, comment: "配送日期"
    add_column :orders, :perfer_time, :string, comment: "配送时间段"
    add_column :orders, :authority_to_leave, :boolean, default: false
  end
end
