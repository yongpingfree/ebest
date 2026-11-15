# frozen_string_literal: true

class AddAuSuburbIdsToPagePopups < ActiveRecord::Migration[5.2]
  def change
    add_column :page_popups, :au_suburb_ids, :integer, array: true, default: []
  end
end
