# frozen_string_literal: true

class AddLeaderToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :leader, :string, comment: "负责人", default: "其他"
  end
end
