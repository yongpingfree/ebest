# frozen_string_literal: true

class AddDetailVideoToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :detail_video, :string
  end
end
