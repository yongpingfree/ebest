# frozen_string_literal: true

class AddBatchReindexDateToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :batch_reindex_date, :date, comment: "每晚批量同步ES日期"
  end
end
