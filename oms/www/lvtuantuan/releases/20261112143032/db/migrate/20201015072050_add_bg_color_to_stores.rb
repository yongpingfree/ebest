# frozen_string_literal: true

class AddBgColorToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :bg_color, :string, default: "#C5EDE7"
  end
end
