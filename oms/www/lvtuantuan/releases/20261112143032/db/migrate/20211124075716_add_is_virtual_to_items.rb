# frozen_string_literal: true

class AddIsVirtualToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :is_virtual, :boolean, default: false
  end
end
