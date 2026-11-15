# frozen_string_literal: true

class AddIsPresellToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :is_presell, :boolean, default: false
    add_column :items, :presell_dispatch_on, :date
  end
end
