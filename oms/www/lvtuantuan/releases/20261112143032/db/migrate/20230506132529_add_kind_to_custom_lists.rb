# frozen_string_literal: true

class AddKindToCustomLists < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_lists, :kind, :integer, comment: "列表类型", default: 1
  end
end
