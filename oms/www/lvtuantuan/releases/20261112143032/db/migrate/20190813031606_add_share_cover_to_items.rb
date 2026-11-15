# frozen_string_literal: true

class AddShareCoverToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :share_cover, :string
  end
end
