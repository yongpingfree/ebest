# frozen_string_literal: true

class AddBgColorToCustomPages < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_pages, :bg_color, :string
  end
end
