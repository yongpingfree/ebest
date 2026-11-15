# frozen_string_literal: true

class AddImageToPushMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :push_messages, :image, :string
  end
end
