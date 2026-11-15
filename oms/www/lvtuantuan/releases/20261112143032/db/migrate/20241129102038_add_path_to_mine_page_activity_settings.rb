# frozen_string_literal: true

class AddPathToMinePageActivitySettings < ActiveRecord::Migration[5.2]
  def change
    add_column :mine_page_activity_settings, :path, :string, comment: "跳转页面路径"
  end
end
