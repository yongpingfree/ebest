# frozen_string_literal: true

class AddDeletedAtToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :deleted_at, :datetime, comment: "软删除时间"
  end
end
