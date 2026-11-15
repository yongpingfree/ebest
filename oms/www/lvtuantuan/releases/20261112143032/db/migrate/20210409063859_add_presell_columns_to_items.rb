# frozen_string_literal: true
class AddPresellColumnsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :presell_end_at, :datetime
    add_column :items, :lastest_presell_dispatch_on, :date
  end
end
