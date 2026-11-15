# frozen_string_literal: true

class AddDueTimeToAfterSales < ActiveRecord::Migration[5.2]
  def change
    add_column :after_sales, :due_time, :datetime
  end
end
