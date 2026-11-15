# frozen_string_literal: true

class RenameChildrenToOrderItems < ActiveRecord::Migration[5.2]
  def change
    rename_column :order_items, :children, :groups
  end
end
